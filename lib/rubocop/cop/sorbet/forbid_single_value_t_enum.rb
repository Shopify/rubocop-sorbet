# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # TODO: Write cop description and example of bad / good code. For every
      # `SupportedStyle` and unique configuration, there needs to be examples.
      # Examples must have valid Ruby syntax. Do not use upticks.
      #
      # @safety
      #   Delete this section if the cop is not unsafe (`Safe: false` or
      #   `SafeAutoCorrect: false`), or use it to explain how the cop is
      #   unsafe.
      #
      # @example EnforcedStyle: bar (default)
      #   # Description of the `bar` style.
      #
      #   # bad
      #   bad_bar_method
      #
      #   # bad
      #   bad_bar_method(args)
      #
      #   # good
      #   good_bar_method
      #
      #   # good
      #   good_bar_method(args)
      #
      # @example EnforcedStyle: foo
      #   # Description of the `foo` style.
      #
      #   # bad
      #   bad_foo_method
      #
      #   # bad
      #   bad_foo_method(args)
      #
      #   # good
      #   good_foo_method
      #
      #   # good
      #   good_foo_method(args)
      #
      class ForbidSingleValueTEnum < Base
        def initialize(*)
          @inside_t_enum = false
          super
        end

        MSG = "`T::Enum` should have at least two values."

        # @!method t_enum?(node)
        def_node_matcher :t_enum?, <<~PATTERN
          (class (const...) (const (const nil? :T) :Enum) ...)
        PATTERN

        # @!method enums_block?(node)
        def_node_matcher :enums_block?, <<~PATTERN
          (block (send nil? :enums) ...)
        PATTERN

        def on_class(node)
          @inside_t_enum = true if t_enum?(node)
        end

        def after_class(node)
          @inside_t_enum = false
        end

        def on_block(node)
          # require "debug"
          # binding.b
          return unless @inside_t_enum
          return unless enums_block?(node)

          begin_node = node.children.find(&:begin_type?)

          num_casgn_nodes = if begin_node
            begin_node.children.count(&:casgn_type?)
          else
            node.children.count(&:casgn_type?)
          end

          add_offense(node) if num_casgn_nodes == 1
        end
      end
    end
  end
end
