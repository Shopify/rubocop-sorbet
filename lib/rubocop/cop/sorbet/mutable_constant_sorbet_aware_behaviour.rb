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
            base.def_node_matcher(:t_type_alias?, <<~PATTERN)
              (block (send (const {nil? cbase} :T) :type_alias ...) ...)
            PATTERN
            base.def_node_matcher(:type_member?, <<~PATTERN)
              (block (send nil? :type_member ...) ...)
            PATTERN
          end
        end

        def on_assignment(value)
          t_let(value) do |constant|
            value = constant
          end
          return if t_type_alias?(value)
          return if type_member?(value)

          super(value)
        end
      end
    end
  end
end

RuboCop::Cop::Style::MutableConstant.prepend(
  RuboCop::Cop::Sorbet::MutableConstantSorbetAwareBehaviour,
)
