# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks that `on_failure` is not used without `checked(:tests)` or `checked(:always)`.
      #
      # @example
      #
      #   # bad
      #   sig { params(x: Integer).returns(Integer).on_failure(:raise) }
      #   def plus_one(x)
      #     x + 1
      #   end
      #
      #   # good
      #   sig { params(x: Integer).returns(Integer).checked(:always).on_failure(:raise) }
      #   def plus_one(x)
      #     x + 1
      #   end
      #
      class RuntimeOnFailureDependsOnChecked < ::RuboCop::Cop::Base
        include SignatureHelp

        MSG = "To use .on_failure you must additionally call .checked(:tests) or .checked(:always), otherwise, the .on_failure has no effect."

        # @!method on_failure_call?(node)
        def_node_matcher :on_failure_call?, <<~PATTERN
          (send _ :on_failure ...)
        PATTERN

        # @!method checked_tests_or_always?(node)
        def_node_matcher :checked_tests_or_always?, <<~PATTERN
          (send _ :checked (sym {:tests | :always}))
        PATTERN

        def on_signature(node)
          return unless node.descendants.any? { |n| on_failure_call?(n) }
          return if node.descendants.any? { |n| checked_tests_or_always?(n) }

          add_offense(node)
        end
      end
    end
  end
end
