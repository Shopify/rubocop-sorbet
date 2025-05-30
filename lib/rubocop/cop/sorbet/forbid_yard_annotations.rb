# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Prevents the use of YARD method annotations (ex. `@param` and `@return`).
      #
      # @safety
      #   While the cop itself is safe to run, auto-correcting might not be safe. It adds a
      #   type definition that may cause your code to break if all calls don't comply with
      #   the new defintion.
      #
      # @example
      #
      #   # bad
      #   # @param name [String] the name
      #   # @return [String] the greeting
      #   def greet(name)
      #     "Hello #{name}"
      #   end
      #
      #   # good
      #   # name: String -> String
      #   def greet(name)
      #     "Hello #{name}"
      #   end
      #
      class ForbidYardAnnotations < Base
        include Alignment
        extend AutoCorrector

        MSG = "Avoid using YARD method annotations. Use RBS comment syntax instead."

        ANY_WHITESPACE = /\s*/

        FORBIDDEN_YARD_TAGS = [
          "option",
          "overload",
          "param",
          "return",
          "yield",
          "yieldparam",
          "yieldreturn",
        ].freeze
        private_constant :FORBIDDEN_YARD_TAGS

        Signature = Struct.new(:params, :return_type, :block_signature, keyword_init: true) do
          def initialize(params: [], return_type: "void", block_signature: nil)
            super
          end

          def to_comment_s
            block_string = block_signature.nil? ? "" : " #{block_signature_s}"
            "#: (#{params.join(", ")})#{block_string} -> #{return_type}"
          end

          def block_signature_s
            return "" unless block_signature

            "{ #{block_signature.to_comment_s.delete_prefix("#: ")} }"
          end
        end
        private_constant :Signature

        def on_new_investigation
          return if processed_source.comments.empty?

          comment_blocks.each do |comment_block|
            signature = Signature.new
            forbidden_blocks = forbidden_yard_tag_blocks(comment_block)
            forbidden_blocks.each_with_index do |tag_block, index|
              add_offense(tag_block.first) do |corrector|
                update_signature(signature, tag_block)
                corrector.remove(range_of_lines_for(tag_block))

                if index + 1 == forbidden_blocks.size
                  corrector.insert_after(
                    comment_block.last.source_range.end.resize(1).end,
                    "#{offset(tag_block.first)}#{signature.to_comment_s}\n",
                  )
                end
              end
            end
          end
        end

        private

        def comment_blocks
          Enumerator.new do |yielder|
            comments = processed_source.comments
            next if comments.empty?

            current_chunk = []
            previous_line = -1

            comments.each do |comment|
              if comment.location.line == previous_line + 1
                current_chunk << comment
              else
                yielder << current_chunk unless current_chunk.empty?
                current_chunk = [comment]
              end

              previous_line = comment.location.line
            end

            yielder << current_chunk unless current_chunk.empty?
          end
        end

        def forbidden_yard_tag_blocks(comment_block)
          return [] if comment_block.empty?

          result = []
          current_tag_chunk = []
          previous_line = -1
          tag_indent_level = 0

          comment_block.each do |comment|
            scanner = StringScanner.new(comment.text)
            next unless scanner.skip("#")

            indent_level = scanner.skip(ANY_WHITESPACE)

            if !current_tag_chunk.empty? &&
                comment.location.line == previous_line + 1 &&
                indent_level >= tag_indent_level + 2
              current_tag_chunk << comment
            else
              result << current_tag_chunk unless current_tag_chunk.empty?
              current_tag_chunk = []

              if scanner.skip("@") && forbidden_yard_tag_next?(scanner)
                current_tag_chunk << comment
                tag_indent_level = indent_level
              end
            end

            previous_line = comment.location.line
          end

          result << current_tag_chunk unless current_tag_chunk.empty?

          result
        end

        def forbidden_yard_tag_next?(scanner)
          FORBIDDEN_YARD_TAGS.any? do |tag_name|
            if scanner.skip(tag_name)
              scanner.unscan unless (match = scanner.eos? || scanner.peek(1).lstrip.empty?)
              match
            else
              false
            end
          end
        end

        def range_of_lines_for(block)
          range = block.first.source_range.join(block.last.source_range)
          range.with(
            begin_pos: range.begin_pos - range.column,
            end_pos: range.end_pos + 1,
          )
        end

        def update_signature(signature, tag_block)
          buffer = tag_block.first.text
          tag_block[1..].each do |comment|
            buffer += comment.text.sub(/^\s*#\s*/, " ")
          end
          scanner = StringScanner.new(buffer)
          scanner.skip_until(/@/)
          tag_name = scanner.scan_until(/\s|$/)
          tag_name&.rstrip!
          return unless FORBIDDEN_YARD_TAGS.include?(tag_name)

          scanner.skip_until(/\[/)
          type = scanner.scan_until(/\]/)
          type&.delete_suffix!("]")
          return unless type

          case tag_name
          when "param"
            signature.params << type
          when "return"
            signature.return_type = type
          when "yield"
            signature.block_signature ||= Signature.new
            signature.block_signature.params = Array.new(type.split(",").size, "untyped")
          when "yieldparam"
            signature.block_signature ||= Signature.new
            signature.block_signature.params << type
          when "yieldreturn"
            signature.block_signature ||= Signature.new
            signature.block_signature.return_type = type
          end
        end
      end
    end
  end
end
