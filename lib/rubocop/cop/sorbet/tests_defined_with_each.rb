# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Checks for tests generated inside `each`. Sorbet only looks for test methods at the top level of a
      # class body or `describe` block, so it cannot see through `each`: `self` stays bound to the example
      # group rather than an instance, and calls inside the loop fail to resolve. `test_each` and
      # `test_each_hash` exist for Sorbet to see through.
      #
      # A loop whose body holds anything Sorbet rejects there -- `it_behaves_like`, a guard clause, an
      # assignment, another loop -- is left alone rather than corrected into an error 3507.
      #
      # @safety
      #   `test_each` and `test_each_hash` are not shipped by `sorbet-runtime`; each project defines its
      #   own. Correcting a project that has not defined them raises `NoMethodError`. `test_each` also
      #   has to accept a `Hash`, since `test_each_hash` is only picked for a hash literal or an
      #   `each_pair` call, not for a hash reached through a variable, constant or method.
      #
      #   Rewriting `|a, b|` to `|(a, b)|` assumes the receiver's `each` yields one value per
      #   iteration (as `Array#each`, `Hash#each` and the rest of the standard library do), which
      #   multiple block parameters were already destructuring. A receiver whose `each` instead
      #   yields multiple values (`yield a, b`, not `yield [a, b]`) is not detected: correcting it
      #   silently drops every value past the first.
      #
      # @example
      #
      #   # bad
      #   [[1, "one"], [2, "two"]].each do |number, name|
      #     it "spells #{number}" do
      #     end
      #   end
      #
      #   # good
      #   test_each([[1, "one"], [2, "two"]]) do |(number, name)|
      #     it "spells #{number}" do
      #     end
      #   end
      #
      #   # bad
      #   { "one" => 1 }.each do |name, number|
      #     it "spells #{number}" do
      #     end
      #   end
      #
      #   # good
      #   test_each_hash({ "one" => 1 }) do |name, number|
      #     it "spells #{number}" do
      #     end
      #   end
      #
      #   # bad
      #   ROWS.each_with_index do |row, index|
      #     it "spells #{row}" do
      #     end
      #   end
      #
      #   # good
      #   test_each(ROWS.each_with_index.to_a) do |(row, index)|
      #     it "spells #{row}" do
      #     end
      #   end
      #
      # @see https://sorbet.org/docs/minitest#table-driven-tests-tests-defined-with-each
      class TestsDefinedWithEach < Base
        extend AutoCorrector

        MSG = "Use `%<replacement>s` so Sorbet can see the tests defined in this loop."
        LOOP_METHODS = [:each, :each_pair, :each_with_index].freeze
        # Anything else at the top level of a `test_each` block raises 3507, so the whole body must be these.
        TEST_METHODS = [
          :after,
          :before,
          :context,
          :describe,
          :include_examples,
          :it,
          :let,
          :shared_examples,
          :specify,
          :subject,
        ].freeze

        def on_block(node)
          return unless offense?(node)

          send_node = node.send_node
          hash = hash_loop?(send_node)
          replacement = hash ? "test_each_hash" : "test_each"

          add_offense(send_node.loc.selector, message: format(MSG, replacement: replacement)) do |corrector|
            corrector.insert_before(send_node.receiver, "#{replacement}(")
            corrector.replace(call_range(send_node), "#{rows_suffix(send_node)})")
            destructure_row(corrector, node) unless hash
          end
        end
        # `test_each` requires an explicit block parameter, so implicit ones bail on the check below.
        alias_method :on_numblock, :on_block
        alias_method :on_itblock, :on_block

        private

        def offense?(node)
          send_node = node.send_node
          return false unless loop?(send_node)
          return false unless send_node.receiver && send_node.arguments.empty?
          return false if node.arguments.empty? || !node.arguments.all?(&:arg_type?)
          return false if lone_indexed_parameter?(send_node, node) || discards_row?(node)
          return false if comment_before_selector?(send_node)
          return false if unparenthesizable?(send_node.receiver) || chained_onto_loop?(send_node.receiver)
          return false if class_receiver?(send_node.receiver) || inside_loop_body?(node)

          defines_tests?(node)
        end

        # A class or module reaches `each` through something other than `Enumerable`, so `test_each`
        # would not receive the collection its signature asks for -- every `T::Enum`, for instance.
        def class_receiver?(receiver)
          receiver.const_type? && receiver.class_name?
        end

        def loop?(send_node)
          send_node.send_type? && LOOP_METHODS.include?(send_node.method_name)
        end

        # Nesting `test_each` in `test_each` raises 3507; overlap since a sole-statement body *is* the loop.
        def inside_loop_body?(node)
          node.each_ancestor(:any_block).any? do |ancestor|
            loop?(ancestor.send_node) && ancestor.body&.source_range&.overlaps?(node.source_range)
          end
        end

        # Everything from the receiver to the end of the call is replaced, which absorbs any `()`.
        def call_range(send_node)
          send_node.receiver.source_range.end.join(send_node.source_range.end)
        end

        # `each_with_index` yields two values, so `to_a` makes each element one `[row, index]` pair.
        def rows_suffix(send_node)
          send_node.method?(:each_with_index) ? ".each_with_index.to_a" : ""
        end

        # A lone parameter is bound to the row itself, which `to_a` would rebind to a `[row, index]` pair.
        def lone_indexed_parameter?(send_node, node)
          send_node.method?(:each_with_index) && node.arguments.one?
        end

        # A trailing comma already discards the rest of the row, which destructuring would change.
        def discards_row?(node)
          !node.arguments.one? && node.arguments.source.delete_suffix("|").end_with?(",")
        end

        # A comment between the receiver and the selector would swallow the closing parenthesis.
        def comment_before_selector?(send_node)
          range = send_node.receiver.source_range.end.join(send_node.loc.selector.begin)
          processed_source.comments.any? { |comment| range.overlaps?(comment.source_range) }
        end

        # A parenthesis-less command taking a block cannot be wrapped in parentheses before Ruby 3.4.
        def unparenthesizable?(node)
          return false if target_ruby_version >= 3.4

          while node&.type?(:any_block, :call)
            unless node.type?(:any_block)
              node = node.receiver
              next
            end

            send_node = node.send_node
            return true if !send_node.arguments.empty? && !send_node.parenthesized?

            node = send_node.receiver
          end
          false
        end

        # Correcting a loop chained onto another correctable loop would clobber that loop's correction.
        def chained_onto_loop?(receiver)
          [receiver, *receiver.each_descendant].any? do |node|
            node.type?(:any_block) && offense?(node)
          end
        end

        def hash_loop?(send_node)
          return false if send_node.method?(:each_with_index)

          send_node.method?(:each_pair) || send_node.receiver.hash_type?
        end

        # `each` yields one row per iteration, which multiple block parameters were already destructuring.
        def destructure_row(corrector, node)
          return if node.arguments.one?

          range = node.first_argument.source_range.join(node.last_argument.source_range)
          corrector.replace(range, "(#{range.source})")
        end

        # All statements, not just one, since a single unaccepted one raises 3507 for the whole block.
        def defines_tests?(node)
          body = node.body
          return false unless body

          statements = body.begin_type? ? body.children : [body]
          statements.all? do |statement|
            send_node = statement.type?(:any_block) ? statement.send_node : statement
            send_node.send_type? && send_node.receiver.nil? && TEST_METHODS.include?(send_node.method_name)
          end
        end
      end
    end
  end
end
