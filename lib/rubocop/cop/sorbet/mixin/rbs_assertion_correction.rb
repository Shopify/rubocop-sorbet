# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Shared guards for replacing Sorbet runtime assertions with RBS inline
      # comments without changing the surrounding Ruby syntax.
      module RBSAssertionCorrection
        include RangeHelp

        COMMENT_START = "#"
        NEWLINES = ["\n", "\r"].freeze

        private

        def rbs_assertion_autocorrectable?(node, allow_assignment: false)
          return false unless cop_config["AutocorrectToRBS"]
          return false unless assertion_ends_line?(node)
          return false if ::RuboCop::Sorbet::RBSParser.rbs_annotation_after(processed_source, node)

          statement = assertion_statement(node, allow_assignment: allow_assignment)
          statement && statement.source_range.source_line.index(/\S/) == statement.source_range.column
        end

        def assertion_statement(node, allow_assignment:)
          parent = node.parent
          return node unless parent&.assignment? && parent.children.last.equal?(node)

          parent if allow_assignment
        end

        def assertion_ends_line?(node)
          range = range_after_horizontal_whitespace(node)
          character = range.source_buffer.source[range.end_pos]

          character.nil? || NEWLINES.include?(character) || character == COMMENT_START
        end

        def range_after_horizontal_whitespace(node)
          range_with_surrounding_space(node.source_range, side: :right, newlines: false)
        end
      end
    end
  end
end
