# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Shared autocorrection helper for cops that unwrap a redundant
      # `T.let(value, Type)` down to `value`.
      #
      # A naive `corrector.replace(t_let_node, value_node.source)` drops heredoc
      # bodies: `value_node.source` stops at the heredoc marker line (`<<~SQL`),
      # and when the `T.let` spans multiple lines its `, Type)` and closing paren
      # sit *after* the heredoc body — so replacing the whole `T.let(...)` range
      # with just the marker deletes the body and terminator, producing an
      # unterminated heredoc. This reattaches every heredoc body nested in
      # `value_node` and extends the replaced range past their terminators.
      module TLetCorrection
        private

        def replace_t_let(corrector, t_let_node, value_node)
          heredocs = value_node.each_node(:any_str).select(&:heredoc?)
          if heredocs.empty?
            corrector.replace(t_let_node, value_node.source)
            return
          end

          # A heredoc body sits on the lines below its marker, so the closing
          # `)` can fall either after the bodies (multi-line, with the type on
          # its own line) or before them (single-line, `T.let(<<~SQL, String)`).
          # Extend the replaced range to whichever ends last so no body is left
          # dangling.
          last_heredoc_end = heredocs.map { |node| node.loc.heredoc_end.end_pos }.max
          paren_end = t_let_node.source_range.end_pos
          range = t_let_node.source_range.with(end_pos: [last_heredoc_end, paren_end].max)

          # When the `)` closes before the bodies, the extended range would also
          # swallow anything trailing it on that line (e.g. a comment), so carry
          # that text back onto the reconstructed marker line.
          inline_tail = ""
          if paren_end < last_heredoc_end
            source = t_let_node.source_range.source_buffer.source
            line_end = source.index("\n", paren_end) || source.length
            inline_tail = source[paren_end...line_end]
          end

          bodies = heredocs
            .sort_by { |node| node.loc.heredoc_body.begin_pos }
            .map { |node| node.loc.heredoc_body.source + node.loc.heredoc_end.source }
          corrector.replace(range, "#{value_node.source}#{inline_tail}\n#{bodies.join("\n")}")
        end
      end
    end
  end
end
