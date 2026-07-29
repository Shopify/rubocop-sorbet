# frozen_string_literal: true

require "rubocop/cop/lint/void"

module RuboCop
  module Cop
    module Sorbet
      # Patches `Lint/Void` to be aware of RBS inline `#: absurd` type
      # assertions, which are used to mark unreachable branches in exhaustive
      # `case`/`when` matching.
      #
      # Without this patch, RuboCop 1.85+ flags the expression in the
      # unreachable branch as "used in void context" because `Lint/Void` now
      # inspects `case`/`when` branch bodies (rubocop/rubocop#14756).
      #
      # @example
      #
      #   # good (not flagged)
      #   #: ((String | Integer) x) -> void
      #   def foo(x)
      #     case x
      #     when String
      #     when Integer
      #     else
      #       x #: absurd
      #     end
      #   end
      module VoidSorbetAwareBehaviour
        RBS_ABSURD_PATTERN = /\A#:\s*absurd\s*\z/

        def check_expression(expr)
          return unless expr
          return if rbs_absurd_assertion?(expr)

          super
        end

        private

        # Checks whether `node` is followed by an RBS `#: absurd` inline
        # comment on the same line, indicating a deliberate unreachable-type
        # assertion that should not be treated as a void-context misuse.
        def rbs_absurd_assertion?(node)
          return false unless node&.source_range

          node_range = node.source_range
          buffer = processed_source.buffer

          processed_source.comments.any? do |comment|
            next false unless comment.loc.line == node_range.last_line

            gap = buffer.source[node_range.end_pos...comment.source_range.begin_pos]
            gap&.match?(/\A[ \t]*\z/) && comment.text.match?(RBS_ABSURD_PATTERN)
          end
        end
      end
    end
  end
end

RuboCop::Cop::Lint::Void.prepend(
  RuboCop::Cop::Sorbet::VoidSorbetAwareBehaviour,
)
