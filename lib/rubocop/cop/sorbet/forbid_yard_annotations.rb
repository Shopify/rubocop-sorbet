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
          yard_type = scanner.scan_until(/\]/)
          yard_type&.delete_suffix!("]")
          return unless yard_type

          type = rbs_type_string_from_yard_type_string(yard_type)

          case tag_name
          when "param"
            signature.params << type
          when "return"
            signature.return_type = type

          # Right now, I'm making a bunch of assumptions. I'm assuming that if the last
          # param is a Hash, then I should delete it when encountering an option. I'm also
          # assuming that if the last param ends with a hash shape ("}"), then I should
          # append the current option to it. It would be better to do this based on matching
          # param names, but I don't currently track or store that.
          when "option"
            key_and_separator = scan_for_option_key_and_separator(scanner)
            return if key_and_separator.empty?

            signature.params.pop if signature.params.last =~ /Hash(?:$|\[)/

            if signature.params.last&.end_with?("}")
              signature.params.last.insert(-3, ", #{key_and_separator} #{type}")
            else
              signature.params << "{ #{key_and_separator} #{type} }"
            end
          when "yield"
            signature.block_signature ||= Signature.new
            signature.block_signature.params = Array.new(yard_type.split(",").size, "untyped")
          when "yieldparam"
            signature.block_signature ||= Signature.new
            signature.block_signature.params << type
          when "yieldreturn"
            signature.block_signature ||= Signature.new
            signature.block_signature.return_type = type
          end
        end

        def rbs_type_string_from_yard_type_string(yard_type_string, join: " | ")
          new_types = []
          scanner = StringScanner.new(yard_type_string)

          scanner.skip(ANY_WHITESPACE)
          while !scanner.eos? && (current_tag = scanner.scan_until(/[,<({]|$/))
            if current_tag.end_with?("<")
              current_tag.chop!
              current_tag = "Array" if current_tag.empty?
              inner_yard_string = scan_until_matching_bracket(scanner, "<>")

              inner_type_string = if current_tag == "Hash"
                rbs_type_string_from_yard_type_string(inner_yard_string, join: ", ")
              else
                rbs_type_string_from_yard_type_string(inner_yard_string)
              end
              new_types << "#{current_tag}[#{inner_type_string}]"
            elsif current_tag.end_with?("{")
              current_tag.chop!
              current_tag = "Hash" if current_tag.empty?
              inner_yard_string = scan_until_matching_bracket(scanner, "{}")

              # For now, don't support nested hashes as keys
              key_yard_string, value_yard_string = inner_yard_string.split("=>", 2)
              key_yard_string&.strip!
              value_yard_string&.strip!
              new_types << "#{current_tag}[#{rbs_type_string_from_yard_type_string(key_yard_string)}, #{rbs_type_string_from_yard_type_string(value_yard_string)}]"
            elsif current_tag.end_with?("(")
              current_tag.chop!
              inner_yard_string = scan_until_matching_bracket(scanner, "()")
              new_types << "[#{rbs_type_string_from_yard_type_string(inner_yard_string, join: ", ")}]"
            else
              current_tag.chop! if current_tag.end_with?(",")
              new_types << rbs_type_from(current_tag) unless current_tag.empty?
            end
            scanner.skip(ANY_WHITESPACE)
          end

          new_types.join(join)
        end

        def rbs_type_from(yard_type)
          case yard_type
          when "Boolean" then "bool"
          when "true" then "TrueClass"
          when "false" then "FalseClass"
          when "nil" then "NilClass"
          when "self", /\A#/ then "untyped"
          when /\A:/ then "Symbol"
          when /\A\d+\z/ then "Integer"
          when /\A\d+\.\d+\z/ then "Float"
          when /\A(?:"|').*(?:"|')\z/ then "String"
          else
            yard_type
          end
        end

        def scan_for_option_key_and_separator(scanner)
          scanner.skip(ANY_WHITESPACE)
          key = scanner.scan_until(/\s|$/)
          key&.rstrip!
          return "" unless key

          if key.start_with?(":")
            key.delete_prefix(":").concat(":")
          else
            key + " =>"
          end
        end

        def scan_until_matching_bracket(scanner, brackets)
          open_char, close_char = brackets.split("", 3)
          current_pos = start_pos = scanner.pos
          bracket_matcher = /[#{Regexp.quote(open_char)}#{Regexp.quote(close_char)}]/
          bracket_count = 1
          while bracket_count > 0 && !scanner.eos?
            break unless scanner.skip_until(bracket_matcher)

            if scanner.matched == open_char
              bracket_count += 1
            elsif scanner.matched == close_char &&
                (close_char != ">" || !scanner.pre_match.end_with?("="))
              bracket_count -= 1
            end

            current_pos = scanner.pos
          end

          scanner.string[start_pos...(current_pos - 1)]
        end
      end
    end
  end
end
