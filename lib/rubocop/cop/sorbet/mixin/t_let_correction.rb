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

        # Replaces `T.let(value, Type)` with `value`.
        def replace_t_let(corrector, t_let_node, value_node)
          heredocs_to_reattach = tail_heredocs(value_node)
          return corrector.replace(t_let_node, value_node.source) if heredocs_to_reattach.empty?

          replace_t_let_preserving_heredocs(corrector, t_let_node, value_node, heredocs_to_reattach)
        end

        # Heredocs at the tail of the value, whose body sits past `value_node`'s
        # source range. An interior heredoc, e.g. `Foo.new(a: <<~X, b: 2)`, already
        # lives inside `value_node.source` and must not be reattached.
        def tail_heredocs(value_node)
          value_end = value_node.source_range.end_pos
          value_node.each_node(:any_str).select do |node|
            node.heredoc? && node.loc.heredoc_end.end_pos > value_end
          end
        end

        # Replaces `T.let(value, Type)` with `value` without losing any heredocs
        # contained in the value. For example, `T.let(<<~SQL, String)` becomes
        # `<<~SQL` followed by its original body and terminator.
        def replace_t_let_preserving_heredocs(corrector, t_let_node, value_node, heredocs)
          corrector.replace(
            range_including_heredocs(t_let_node, heredocs),
            source_including_heredocs(value_node, heredocs),
          )
        end

        # Expands the correction range to include every heredoc body and terminator.
        # For example, the range for `T.let(<<~SQL, String)` extends through the
        # final `SQL` terminator rather than ending at the closing parenthesis.
        def range_including_heredocs(t_let_node, heredocs)
          end_positions = [t_let_node.source_range.end_pos]
          end_positions.concat(heredocs.map { |node| node.loc.heredoc_end.end_pos })
          t_let_node.source_range.with(end_pos: end_positions.max)
        end

        # Reconstructs the value with its marker-line comment and heredoc bodies.
        # For example, `T.let(<<~SQL, String) # query` becomes a source string
        # containing `<<~SQL # query`, followed by its body and `SQL` terminator.
        def source_including_heredocs(value_node, heredocs)
          marker_line = "#{value_node.source}#{marker_line_comment(value_node)}"
          heredoc_bodies = heredocs
            .sort_by { |node| node.loc.heredoc_body.begin_pos }
            .map { |node| "#{node.loc.heredoc_body.source}#{node.loc.heredoc_end.source}" }

          ([marker_line] + heredoc_bodies).join("\n")
        end

        # Returns the comment trailing the heredoc marker, including its leading space.
        # For example, the marker line `<<~SQL, String) # query` returns ` # query`.
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
