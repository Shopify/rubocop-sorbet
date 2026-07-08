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

          # The closing `)` may come before (single-line) or after (multi-line)
          # the heredoc bodies, so extend to whichever ends last.
          end_pos = heredocs.map { |node| node.loc.heredoc_end.end_pos }.push(t_let_node.source_range.end_pos).max
          range = t_let_node.source_range.with(end_pos: end_pos)

          bodies = heredocs
            .sort_by { |node| node.loc.heredoc_body.begin_pos }
            .map { |node| node.loc.heredoc_body.source + node.loc.heredoc_end.source }
          corrector.replace(range, "#{value_node.source}\n#{bodies.join("\n")}")
        end
      end
    end
  end
end
