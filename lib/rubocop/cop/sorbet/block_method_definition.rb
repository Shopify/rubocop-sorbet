# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Disallow defining methods in blocks, to prevent running into issues
      # caused by https://github.com/sorbet/sorbet/issues/3609.
      #
      # As a workaround, use `define_method` instead.
      #
      # The one exception is for `Class.new` blocks, as long as the result is
      # assigned to a constant (i.e. as long as it is not an anonymous class).

      # @example
      #   # bad
      #   yielding_method do
      #     def bad(args)
      #       # ...
      #     end
      #   end
      #
      #   # bad
      #   Class.new do
      #     def bad(args)
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   yielding_method do
      #     define_method(:good) do |args|
      #       # ...
      #     end
      #   end
      #
      #   # good
      #   MyClass = Class.new do
      #     def good(args)
      #       # ...
      #     end
      #   end
      #
      class BlockMethodDefinition < Base
        include RuboCop::Cop::Alignment
        extend AutoCorrector

        MSG = "Do not define methods in blocks (use `define_method` as a workaround)."

        def on_block(node)
          if (parent = node.parent)
            return if parent.casgn_type?
          end

          node.each_descendant(:any_def) do |def_node|
            add_offense(def_node) do |corrector|
              autocorrect_method_in_block(corrector, def_node)
            end
          end
        end
        alias_method :on_numblock, :on_block

        private

        def autocorrect_method_in_block(corrector, node)
          indent = offset(node)

          method_name = node.method_name
          args = node.arguments.map(&:source).join(", ")
          args = " |#{args}|" unless args.empty?
          body = node.body&.source&.prepend("\n#{indent}  ")

          if node.def_type?
            replacement = "define_method(:#{method_name}) do#{args}#{body}\n#{indent}end"
          elsif node.defs_type?
            receiver = node.receiver.source
            replacement = "#{receiver}.define_singleton_method(:#{method_name}) do#{args}#{body}\n#{indent}end"
          end

          corrector.replace(node, replacement)
        end
      end
    end
  end
end
