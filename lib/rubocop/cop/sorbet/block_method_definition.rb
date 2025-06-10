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
      # Another exception is for ActiveSupport::Concern `class_methods` blocks.
      #
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
      #   # good
      #   module SomeConcern
      #     extend ActiveSupport::Concern
      #
      #     class_methods do
      #       def good(args)
      #         # ...
      #       end
      #     end
      #   end
      #
      class BlockMethodDefinition < Base
        include RuboCop::Cop::Alignment
        extend AutoCorrector

        MSG = "Do not define methods in blocks (use `define_method` as a workaround)."

        # @!method activesupport_concern_class_methods_block?(node)
        def_node_matcher :activesupport_concern_class_methods_block?, <<~PATTERN
          (block
            (send nil? :class_methods)
            _
            _
          )
        PATTERN

        # @!method module_extends_activesupport_concern?(node)
        def_node_matcher :module_extends_activesupport_concern?, <<~PATTERN
          (module _
            (begin
              <(send nil? :extend (const (const {nil? cbase} :ActiveSupport) :Concern)) ...>
              ...
            )
          )
        PATTERN

        def on_block(node)
          if (parent = node.parent)
            return if parent.casgn_type?
          end

          # Check if this is a class_methods block inside an ActiveSupport::Concern
          return if in_activesupport_concern_class_methods_block?(node)

          node.each_descendant(:any_def) do |def_node|
            add_offense(def_node) do |corrector|
              autocorrect_method_in_block(corrector, def_node)
            end
          end
        end
        alias_method :on_numblock, :on_block

        private

        def in_activesupport_concern_class_methods_block?(node)
          return false unless activesupport_concern_class_methods_block?(node)

          immediate_module = node.each_ancestor(:module).first

          module_extends_activesupport_concern?(immediate_module)
        end

        def autocorrect_method_in_block(corrector, node)
          indent = offset(node)

          method_name = node.method_name
          args = node.arguments.map(&:source).join(", ")
          args = " |#{args}|" unless args.empty?

          # Build the method signature replacement
          if node.def_type?
            signature_replacement = "define_method(:#{method_name}) do#{args}"
          elsif node.defs_type?
            receiver = node.receiver.source
            signature_replacement = "#{receiver}.define_singleton_method(:#{method_name}) do#{args}"
          end

          if node.body
            end_pos = node.body.source_range.begin_pos

            body_replacement = "\n#{indent}  "
          else
            end_pos = node.loc.end.begin_pos

            body_replacement = "\n#{indent}"
          end

          signature_range = node.source_range.with(end_pos: end_pos)

          corrector.replace(signature_range, signature_replacement + body_replacement)
        end
      end
    end
  end
end
