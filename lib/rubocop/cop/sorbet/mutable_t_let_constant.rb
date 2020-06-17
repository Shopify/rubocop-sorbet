# encoding: utf-8
# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module Sorbet
      # This cop checks that arguments to T.let calls assigned to constants
      # aren't mutable literals (e.g. array or hash). It is inspired by the
      # Style/MutableConstant cop, but enforced on the argument to T.let,
      # rather than the T.let call itself. (Note that freezing a T.let call
      # will not satisfy the requirements of `# typed: strict` mode.)
      #
      # @see Rubocop::Cop::Style::MutableConstant
      #
      # @example EnforcedStyle: literals (default)
      #   # bad
      #   CONST = T.let([1, 2, 3], T::Array[Integer])
      #
      #   # good
      #   CONST = T.let([1, 2, 3].freeze, T::Array[Integer])
      #
      #   # good
      #   CONST = T.let(Something.new, Something)
      #
      # @example EnforcedStyle: strict
      #   # bad
      #   CONST = T.let(Something.new, Something)
      #
      #   # good
      #   CONST = T.let(Something.new.freeze, Something)
      class MutableTLetConstant < RuboCop::Cop::Cop
        include FrozenStringLiteral
        include ConfigurableEnforcedStyle

        MSG = 'Freeze mutable objects in T.let expressions assigned to constants.'

        def on_casgn(node)
          _scope, _const_name, value = *node

          t_let(value) do |constant|
            on_assignment(constant)
          end
        end

        def on_or_asgn(node)
          lhs, value = *node

          return unless lhs&.casgn_type?

          t_let(value) do |constant|
            on_assignment(constant)
          end
        end

        def autocorrect(node)
          expr = node.source_range

          lambda do |corrector|
            splat_value = splat_value(node)
            if splat_value
              correct_splat_expansion(corrector, expr, splat_value)
            elsif node.array_type? && !node.bracketed?
              corrector.wrap(expr, '[', ']')
            elsif requires_parentheses?(node)
              corrector.wrap(expr, '(', ')')
            end

            corrector.insert_after(expr, '.freeze')
          end
        end

        private

        def on_assignment(value)
          if style == :strict
            strict_check(value)
          else
            check(value)
          end
        end

        def strict_check(value)
          return if immutable_literal?(value)
          return if operation_produces_immutable_object?(value)
          return if frozen_string_literal?(value)

          add_offense(value)
        end

        def check(value)
          range_enclosed_in_parentheses = range_enclosed_in_parentheses?(value)

          return unless mutable_literal?(value) ||
                        range_enclosed_in_parentheses
          return if FROZEN_STRING_LITERAL_TYPES.include?(value.type) &&
                    frozen_string_literals_enabled?

          add_offense(value)
        end

        def mutable_literal?(value)
          value&.mutable_literal?
        end

        def immutable_literal?(node)
          node.nil? || node.immutable_literal?
        end

        def frozen_string_literal?(node)
          FROZEN_STRING_LITERAL_TYPES.include?(node.type) &&
            frozen_string_literals_enabled?
        end

        def requires_parentheses?(node)
          node.range_type? ||
            (node.send_type? && node.loc.dot.nil?)
        end

        def correct_splat_expansion(corrector, expr, splat_value)
          if range_enclosed_in_parentheses?(splat_value)
            corrector.replace(expr, "#{splat_value.source}.to_a")
          else
            corrector.replace(expr, "(#{splat_value.source}).to_a")
          end
        end

        def_node_matcher :splat_value, <<~PATTERN
          (array (splat $_))
        PATTERN

        # Some of these patterns may not actually return an immutable object,
        # but we want to consider them immutable for this cop.
        def_node_matcher :operation_produces_immutable_object?, <<~PATTERN
          {
            (const _ _)
            (send (const nil? :Struct) :new ...)
            (block (send (const nil? :Struct) :new ...) ...)
            (send _ :freeze)
            (send {float int} {:+ :- :* :** :/ :% :<<} _)
            (send _ {:+ :- :* :** :/ :%} {float int})
            (send _ {:== :=== :!= :<= :>= :< :>} _)
            (send (const nil? :ENV) :[] _)
            (or (send (const nil? :ENV) :[] _) _)
            (send _ {:count :length :size} ...)
            (block (send _ {:count :length :size} ...) ...)
          }
        PATTERN

        def_node_matcher :range_enclosed_in_parentheses?, <<~PATTERN
          (begin ({irange erange} _ _))
        PATTERN

        def_node_matcher :t_let, <<~PATTERN
          (send (const nil? :T) :let $_constant _type)
        PATTERN
      end
    end
  end
end
