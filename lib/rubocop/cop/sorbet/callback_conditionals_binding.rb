# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # This cop ensures that callback conditionals are bound to the right type
      # so that they are type checked properly.
      #
      # @example
      #
      #   # bad
      #   class Post < ApplicationRecord
      #     before_create :do_it, if: -> { should_do_it? }
      #
      #     def should_do_it?
      #       true
      #     end
      #   end
      #
      #   # good
      #   class Post < ApplicationRecord
      #     before_create :do_it, if: -> { T.bind(self, Post).should_do_it? }
      #
      #     def should_do_it?
      #       true
      #     end
      #   end
      class CallbackConditionalsBinding < RuboCop::Cop::Cop
        CALLBACKS = %i(before_create).freeze
        include RangeHelp

        def autocorrect(node)
          lambda do |corrector|
            options = node.each_child_node.find(&:hash_type?)

            conditional = nil
            options.each_pair do |keyword, block|
              if keyword.value == :if || keyword.value == :unless
                conditional = block
                break
              end
            end

            _, _, block = conditional.child_nodes
            expected_class = node.parent.child_nodes.first.source

            bind = if block.begin_type?
              indentation = " " * block.child_nodes.first.loc.column
              "T.bind(self, #{expected_class})\n#{indentation}"
            elsif block.child_nodes.empty?
              "T.bind(self, #{expected_class})."
            else
              "T.bind(self, #{expected_class}); "
            end

            corrector.insert_before(block, bind)
          end
        end

        def on_send(node)
          return unless CALLBACKS.include?(node.method_name)

          options = node.each_child_node.find(&:hash_type?)

          conditional = nil
          options.each_pair do |keyword, block|
            if keyword.value == :if || keyword.value == :unless
              conditional = block
              break
            end
          end

          return if conditional.nil?

          type, _, block = conditional.child_nodes
          return unless type.lambda_or_proc?

          expected_class = node.parent.child_nodes.first.source

          unless block.source.include?("T.bind(self, #{expected_class})")
            add_offense(
              node,
              message: "Callback conditionals should be bound to the right type. Use T.bind(self, #{expected_class})"
            )
          end
        end
      end
    end
  end
end
