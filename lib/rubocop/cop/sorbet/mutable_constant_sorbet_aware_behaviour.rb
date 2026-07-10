# frozen_string_literal: true

require "rubocop/cop/style/mutable_constant"

module RuboCop
  module Cop
    module Sorbet
      module MutableConstantSorbetAwareBehaviour
        class << self
          def prepended(base)
            # @!method t_let(node)
            base.def_node_matcher(:t_let, <<~PATTERN)
              (send (const nil? :T) :let $_constant _type)
            PATTERN

            # @!method sorbet_type_declaration?(node)
            base.def_node_matcher(:sorbet_type_declaration?, <<~PATTERN)
              {
                (send nil? {:type_member :type_template} ...)
                (block (send nil? {:type_member :type_template} ...) ...)
                (send (const nil? :T) :type_alias ...)
                (block (send (const nil? :T) :type_alias ...) ...)
              }
            PATTERN
          end
        end

        def on_assignment(value)
          # Sorbet type declarations such as `type_member`, `type_template`,
          # and `T.type_alias` produce type objects that cannot be frozen
          # (calling `.freeze` on them breaks Sorbet), so they are exempt.
          return if sorbet_type_declaration?(value)

          t_let(value) do |constant|
            value = constant
          end

          super(value)
        end
      end
    end
  end
end

RuboCop::Cop::Style::MutableConstant.prepend(
  RuboCop::Cop::Sorbet::MutableConstantSorbetAwareBehaviour,
)
