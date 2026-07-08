# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Shared autocorrection helper for cops that unwrap a redundant
      # `T.let(value, Type)` down to `value`, preserving heredoc bodies that a
      # naive `corrector.replace(t_let_node, value_node.source)` would drop
      # (`value_node.source` stops at the marker line, so the body and its
      # terminator sit outside it).
      module TLetCorrection
        private

        def replace_t_let(corrector, t_let_node, value_node)
          heredocs = value_node.each_node(:any_str).select(&:heredoc?)
          if heredocs.empty?
            corrector.replace(t_let_node, value_node.source)
            return
          end

          # The `T.let(...)` closing paren can fall after the heredoc bodies
          # (multi-line, type on its own line) or before them (single-line,
          # `T.let(<<~SQL, String)`). Extend the replaced range to whichever
          # ends last so no body is left dangling.
          last_heredoc_end = heredocs.map { |node| node.loc.heredoc_end.end_pos }.max
          paren_end = t_let_node.source_range.end_pos
          range = t_let_node.source_range.with(end_pos: [last_heredoc_end, paren_end].max)

          # A comment can trail the value on the marker line (before the body);
          # the extended range would delete it, so recover it and re-emit it on
          # the reconstructed marker line. Only a comment can appear there once
          # the value's source ends — the `, Type)` tokens carry no `#`.
          bodies = heredocs
            .sort_by { |node| node.loc.heredoc_body.begin_pos }
            .map { |node| node.loc.heredoc_body.source + node.loc.heredoc_end.source }
          corrector.replace(range, "#{value_node.source}#{marker_line_comment(value_node)}\n#{bodies.join("\n")}")
        end

        def marker_line_comment(value_node)
          buffer = value_node.source_range.source_buffer.source
          value_end = value_node.source_range.end_pos
          line_end = buffer.index("\n", value_end) || buffer.length
          comment = buffer[value_end...line_end][/#.*/]
          comment ? " #{comment}" : ""
        end
      end
    end
  end
end
