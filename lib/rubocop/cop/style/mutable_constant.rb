# frozen_string_literal: true

return unless defined?(RuboCop::Cop::Style::MutableConstant)

module RuboCop
  module Cop
    module Style
      class MutableConstant
        module SorbetAwareExtension
          include RuboCop::Cop::RangeHelp

          def on_assignment(value)
            t_let(value) do |constant|
              value = constant
            end

            super(value)
          end
        end

        prepend SorbetAwareExtension

        def_node_matcher :t_let, <<~PATTERN
          (send (const nil? :T) :let $_constant _type)
        PATTERN
      end
    end
  end
end
