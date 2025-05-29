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

        def on_new_investigation
          return if processed_source.comments.empty?

          yard_tag_blocks.each do |block|
            next unless (tag_block = block.first)
            next unless contains_forbidden_yard_tag?(tag_block.text)

            add_offense(tag_block)
          end
        end

        private

        def yard_tag_blocks
          Enumerator.new do |yielder|
            comments = processed_source.comments
            next if comments.empty?

            current_tag_chunk = []
            previous_line = -1
            tag_indent_level = 0

            comments.each do |comment|
              scanner = StringScanner.new(comment.text)
              next unless scanner.skip("#")

              indent_level = scanner.skip(ANY_WHITESPACE)

              if !current_tag_chunk.empty? &&
                  comment.location.line == previous_line + 1 &&
                  indent_level >= tag_indent_level + 2
                current_tag_chunk << comment
              else
                yielder << current_tag_chunk unless current_tag_chunk.empty?
                current_tag_chunk = []

                if scanner.skip("@")
                  current_tag_chunk << comment
                  tag_indent_level = indent_level
                end
              end

              previous_line = comment.location.line
            end

            yielder << current_tag_chunk unless current_tag_chunk.empty?
          end
        end

        def contains_forbidden_yard_tag?(comment_text)
          scanner = StringScanner.new(comment_text)
          return false unless scanner.skip("#")

          scanner.skip(ANY_WHITESPACE)

          return false unless scanner.skip("@")

          FORBIDDEN_YARD_TAGS.any? do |tag_name|
            if scanner.skip(tag_name)
              scanner.unscan unless (match = scanner.eos? || scanner.peek(1).lstrip.empty?)
              match
            else
              false
            end
          end
        end
      end
    end
  end
end
