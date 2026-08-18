# frozen_string_literal: true

require "rbs"

module RuboCop
  module Sorbet
    # Pure helpers for parsing RBS inline-comment signatures (`#:` / `#|`).
    #
    # Every public method takes a `processed_source` and/or comment nodes
    # explicitly, so this module is usable both from a Cop and from a plain
    # service class such as
    # `RuboCop::Cop::Sorbet::EnforceSignatures::RBSSignatureChecker`.
    # No Cop::Base state is required.
    #
    # `rbs_signatures_before` returns `Signature` objects that encapsulate one
    # RBS overload each. `rbs_annotation_after` returns the trailing RBS
    # annotation attached to an expression and its comment node.
    # `rbs_comment?` and `rbs_tokens` identify RBS comments and split them
    # into RBS tokens whose positions map back into the comment.
    module RBSParser
      # `#:` begins an RBS signature (each repeated `#:` line is a new overload).
      RBS_SIGNATURE_PREFIX = /\A#:/
      # `#|` continues the preceding `#:` signature (e.g. multiline params/returns).
      RBS_CONTINUATION_PREFIX = /\A#\|/
      WHITESPACE = :tTRIVIA
      END_OF_INPUT = :pEOF

      class << self
        # The RBS signatures attached to `node`, one `Signature` per overload.
        # Climbs `private`/`public`/other send wrappers, collects the contiguous
        # comment block above the unwrapped node, and groups the RBS comments.
        # A signature separated from the method by a blank line is not attached.
        def rbs_signatures_before(processed_source, node)
          node = node.parent while node.parent&.send_type?
          rbs_signature_groups(comments_above(processed_source, node))
            .map { |group| Signature.new(processed_source, group) }
        end

        # The trailing RBS annotation attached to `node`, as `[comment, text]`.
        # The comment must follow the expression on its final line with only
        # horizontal whitespace between them.
        def rbs_annotation_after(processed_source, node)
          last_line = node.source_range.last_line
          comment = processed_source.each_comment_in_lines(last_line..last_line).find do |candidate|
            next false if candidate.source_range.begin_pos < node.source_range.end_pos

            gap = processed_source.buffer.source[node.source_range.end_pos...candidate.source_range.begin_pos]
            gap.match?(/\A[ \t]*\z/)
          end
          return unless comment&.text&.match?(RBS_SIGNATURE_PREFIX)

          annotation = comment.text.sub(RBS_SIGNATURE_PREFIX, "").strip
          return if annotation.empty?

          [comment, annotation]
        end

        def rbs_comment?(comment)
          comment.text.match?(RBS_SIGNATURE_PREFIX) ||
            comment.text.match?(RBS_CONTINUATION_PREFIX)
        end

        # Split a comment into RBS tokens, with the leading `#:`/`#|`, whitespace,
        # and end-of-input marker dropped. Empty for non-RBS comments.
        def rbs_tokens(comment)
          return [] unless rbs_comment?(comment)

          comment_text = "  #{comment.text[2..]}"
          ::RBS::Parser.lex(comment_text).value.reject do |token|
            token.type == WHITESPACE || token.type == END_OF_INPUT
          end
        end

        private

        # Group already-collected comments into RBS signatures. A `#:` line begins
        # a new overload; subsequent `#|` lines continue it. Non-RBS comments are
        # skipped.
        def rbs_signature_groups(comments)
          groups = []
          comments.each do |comment|
            case comment.text
            when RBS_SIGNATURE_PREFIX
              groups << [comment]
            when RBS_CONTINUATION_PREFIX
              groups.last << comment if groups.any?
            end
          end
          groups
        end

        # Comments forming a contiguous block immediately above `node`, in source
        # order. A blank line or non-comment sibling breaks the run.
        def comments_above(processed_source, node)
          comments = processed_source
            .ast_with_comments[node]
            .select { |comment| comment.loc.line < node.loc.line }
            .sort_by { |comment| comment.loc.line }
          return [] if comments.empty?

          block = []
          expected = node.loc.line
          comments.reverse_each do |comment|
            break unless comment.loc.line + 1 == expected

            block.unshift(comment)
            expected = comment.loc.line
          end
          block
        end
      end

      # One RBS signature (a `#:` line plus any `#|` continuation lines).
      # Encapsulates the parsed structure so callers query the signature rather
      # than re-parsing comments through the module.
      class Signature
        attr_reader :comments

        def initialize(processed_source, comments)
          @processed_source = processed_source
          @comments = comments
        end

        # The return type expression as a string (e.g. `"String"`, `"void"`,
        # `"^(Integer) -> void"`, `"Integer | String"`), or nil if the
        # signature has no return arrow or an empty return.
        def return_type
          parsed[:expr]
        end

        # `[highlight_range, replace_range]` covering the return type
        # expression, or nil if there is no return type. `highlight_range`
        # covers the first token (which may span `#|` lines); `replace_range`
        # covers the entire return expression.
        def return_type_range
          return unless parsed[:expr]

          [parsed[:highlight], parsed[:replace]]
        end

        # True if the signature declares a `void` return type.
        def void?
          return_type == "void"
        end

        private

        def parsed
          @parsed ||= compute
        end

        def compute
          segments = @comments.map { |comment| strip_rbs_prefix(comment.text) }
          joined = segments.map(&:first).join(" ")
          arrow_idx = method_arrow_index(joined)
          return {} unless arrow_idx

          expr = joined[(arrow_idx + 2)..].strip
          return {} if expr.empty?

          first_token = expr[/\S+/]
          token_start = joined.index(first_token, arrow_idx + 2)
          highlight = range_for_token(segments, token_start, first_token.length)
          replace_end = return_end_pos(segments)
          replace = Parser::Source::Range.new(@processed_source.buffer, highlight.begin_pos, replace_end)
          { expr: expr, highlight: highlight, replace: replace }
        end

        # Index of the method return arrow: the first `->` at the top level,
        # i.e. outside parameter/block/proc delimiters. A proc return type such
        # as `^(Integer) -> void` has its own nested arrow that must not be
        # mistaken for the method arrow.
        def method_arrow_index(joined)
          depth = 0
          joined.each_char.with_index do |char, index|
            case char
            when "(", "[", "{"
              depth += 1
            when ")", "]", "}"
              depth -= 1
            when "-"
              return index if depth.zero? && joined[index + 1] == ">"
            end
          end
          nil
        end

        # Map a position within the joined signature back to the originating
        # comment and build a source range covering `length` characters.
        def range_for_token(segments, token_start, length)
          offset = 0
          @comments.each_with_index do |comment, index|
            content, prefix_len = segments[index]
            seg_end = offset + content.length
            if token_start < seg_end
              content_offset = token_start - offset
              line_start = @processed_source.buffer.line_range(comment.loc.line).begin_pos
              start_pos = line_start + comment.loc.column + prefix_len + content_offset
              return Parser::Source::Range.new(@processed_source.buffer, start_pos, start_pos + length)
            end
            offset = seg_end + 1 # +1 for the join space
          end
          nil
        end

        # Source position at the end of the group's last non-blank signature
        # content; the return type expression runs to here.
        def return_end_pos(segments)
          last_comment = @comments.last
          _, prefix_len = segments.last
          content = segments.last.first.rstrip
          line_start = @processed_source.buffer.line_range(last_comment.loc.line).begin_pos
          line_start + last_comment.loc.column + prefix_len + content.length
        end

        # Strip the leading `#:`/`#|` marker and surrounding whitespace,
        # returning `[content, prefix_length]`. `prefix_length` is the number
        # of characters consumed from the original text, for mapping
        # joined-content positions back to source offsets.
        def strip_rbs_prefix(text)
          match = text.match(/\A#[:|]\s*/)
          return [text, 0] unless match

          [match.post_match, match[0].length]
        end
      end
    end
  end
end
