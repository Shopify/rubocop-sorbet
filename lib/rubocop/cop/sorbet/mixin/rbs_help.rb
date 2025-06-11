# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      module RBSHelp
        RBS_COMMENT_REGEX = /^#:.*$/

        def rbs_comment?(comment)
          RBS_COMMENT_REGEX.match?(comment.text)
        end

        def has_rbs_comment?(node)
          preceeding_comments(node).any? { |comment| rbs_comment?(comment) }
        end

        def preceeding_comments(node)
          comments = []

          last_line = node.loc.line

          processed_source.ast_with_comments[node].reverse_each do |comment|
            next if comment.loc.line >= last_line
            break if comment.loc.line < last_line - 1

            comments << comment
            last_line = comment.loc.line
          end

          comments.reverse
        end
      end
    end
  end
end
