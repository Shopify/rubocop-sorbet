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
    module RBSParser
      # `#:` begins an RBS signature (each repeated `#:` line is a new overload).
      RBS_SIGNATURE_PREFIX = /\A#:/
      # `#|` continues the preceding `#:` signature (e.g. multiline params/returns).
      RBS_CONTINUATION_PREFIX = /\A#\|/

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

        # The return type expression as a string, or nil if parsing fails.
        def return_type
          return_type_node&.to_s
        end

        # `[highlight_range, replace_range]` covering the return type, or nil
        # if parsing fails or the return type has no source location.
        def return_type_range
          location = return_type_node&.location
          return unless location

          buffer = @processed_source.buffer
          return_source = location.source
          first_token = return_source.match(/\S+/)
          return unless first_token

          highlight_start = location.start_pos + return_source.byteslice(0, first_token.begin(0)).bytesize
          highlight_end = highlight_start + first_token[0].bytesize
          highlight = Parser::Source::Range.new(buffer, highlight_start, highlight_end)
          replace = Parser::Source::Range.new(buffer, location.start_pos, location.end_pos)
          [highlight, replace]
        end

        # True if the signature declares a `void` return type.
        def void?
          return_type_node.is_a?(RBS::Types::Bases::Void)
        end

        private

        def return_type_node
          parsed_method_type&.type&.return_type
        end

        def parsed_method_type
          return @parsed_method_type if defined?(@parsed_method_type)

          source_buffer = RBS::Buffer.new(
            name: @processed_source.buffer.name,
            content: @processed_source.buffer.source,
          )
          body_ranges = @comments.map do |comment|
            marker = comment.text.match(/\A#[:|]\s*/)
            range = comment.source_range
            start_pos = range.begin_pos + marker[0].bytesize
            start_pos...range.end_pos
          end
          comment_buffer = source_buffer.sub_buffer(lines: body_ranges)
          @parsed_method_type = RBS::Parser.parse_method_type(comment_buffer, require_eof: true)
        rescue RBS::ParsingError
          @parsed_method_type = nil
        end
      end
    end
  end
end
