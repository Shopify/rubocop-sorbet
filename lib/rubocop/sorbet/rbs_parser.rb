# frozen_string_literal: true

require "rbs"

module RuboCop
  module Sorbet
    # Pure helpers for parsing RBS inline-comment signatures (`#:` / `#|`).
    #
    # `rbs_signatures_before` returns the comment groups attached to a node
    # (one Array of comment nodes per `#:` overload). `return_type_range`
    # parses a group's normalized method-type text with the `rbs` gem and maps
    # the return type's location back to source ranges, so `SetterReturnType`
    # can highlight and replace the return expression.
    #
    # Every public method takes a `processed_source` and/or comment nodes
    # explicitly, so this module is usable both from a Cop and from a plain
    # service class. No Cop::Base state is required.
    module RBSParser
      # `#:` begins an RBS signature (each repeated `#:` line is a new overload).
      RBS_SIGNATURE_PREFIX = /\A#\s*:/
      # `#|` continues the preceding `#:` signature (e.g. multiline params/returns).
      RBS_CONTINUATION_PREFIX = /\A#\s*\|/

      class << self
        # The RBS signature comment groups attached to `node`, one Array of
        # comment nodes per `#:` overload. Climbs `private`/`public`/other send
        # wrappers, collects the contiguous comment block above the unwrapped
        # node, and groups the RBS comments. A signature separated from the
        # method by a blank line is not attached.
        def rbs_signatures_before(processed_source, node)
          node = node.parent while node.parent&.send_type?
          rbs_signature_groups(comments_above(processed_source, node))
        end

        # For one RBS signature (a comment group), parse its method-type text
        # with `RBS::Parser` and return `[highlight_range, replace_range]`
        # covering the return type, or nil if the signature has no return type,
        # is malformed, or already declares `void`. `replace_range` covers the
        # whole return expression; `highlight_range` covers its first token.
        #
        # The comment contents (excluding `#:`/`#|` markers) are assembled into
        # an `RBS::Buffer` sub-buffer of the Ruby source, so positions the gem
        # reports resolve directly to Ruby source offsets — no manual offset
        # mapping. `require_eof: true` turns trailing tokens (e.g. an
        # unparenthesized `| String`) into a parse error, so malformed
        # signatures yield nil instead of a destructive partial correction.
        def return_type_range(processed_source, comments)
          content_ranges = comments.map do |comment|
            prefix_len = rbs_marker_length(comment.text)
            (comment.loc.expression.begin_pos + prefix_len)...comment.loc.expression.end_pos
          end
          source_buffer = RBS::Buffer.new(name: processed_source.buffer.name, content: processed_source.buffer.source)
          sub = source_buffer.sub_buffer(lines: content_ranges)

          method_type =
            begin
              RBS::Parser.parse_method_type(sub, require_eof: true)
            rescue RBS::ParsingError
              nil
            end
          return unless method_type

          return_type = method_type.type.return_type
          # `void` setters are correct; nothing to correct or flag.
          return if return_type.is_a?(RBS::Types::Bases::Void)

          loc = return_type.location
          return unless loc

          start_pos = loc.start_pos
          replace = Parser::Source::Range.new(processed_source.buffer, start_pos, loc.end_pos)
          token = replace.source[/\S+/]
          highlight = Parser::Source::Range.new(processed_source.buffer, start_pos, start_pos + token.length)
          [highlight, replace]
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

        # Length of the leading `#:`/`#|` marker (including surrounding
        # whitespace) so the signature content can be sliced from the comment.
        def rbs_marker_length(text)
          match = text.match(/\A#\s*[:|]\s*/)
          match ? match[0].length : 0
        end
      end
    end
  end
end
