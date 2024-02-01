# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks that gem versions in RBI annotations are properly formatted per the Bundler gem specification.
      #
      # @example
      #   # bad
      #   # @version "random string"
      #
      #   # good
      #   # @version 1
      #
      #   # good
      #   # @version > 1.2.3
      #
      #   # good
      #   # @version <= 4.3-preview
      #
      class ValidVersionAnnotations < Base
        MSG = "Gem versions must be properly formatted per Bundler's gem specification."
        VERSION_PREFIX = "@version"

        def on_new_investigation
          processed_source.comments.each do |comment|
            comment_text = comment_text(comment)
            next unless version_annotation?(comment_text)

            no_prefix_comment_text = comment_text.delete_prefix(VERSION_PREFIX)
            splits = split_with_offsets(no_prefix_comment_text, ",")
            puts splits.to_a
            splits.each_with_index do |tuple, idx|
              start, finish = tuple
              puts "start: ", start
              puts "finish: ", finish
              version = no_prefix_comment_text[start..finish - 1]
              puts "version: ", version
              add_offense(Parser::Source::Range.new(
                processed_source.buffer,
                comment.loc.column + 2 + VERSION_PREFIX.length + 1 +  idx + start,
                comment.loc.column + 2 + VERSION_PREFIX.length + 1 +  idx + finish,
              )) unless valid_version?(version)
            end
          end
        end

        private

        def version_annotation?(comment)
          comment.start_with?(VERSION_PREFIX)
        end

        def valid_version?(comment)
          parts = comment.split(" ")
          return false if parts.length == 1

          version = parts[1]

          begin
            Gem::Version.new(version)
          rescue ArgumentError
            return false
          end

          true
        end

        def comment_text(comment)
          parts = comment.text.split(" ")
          parts.shift # remove the "#" symbol
          parts.join(" ")
        end

        # https://stackoverflow.com/questions/40390029/how-do-i-figure-out-the-indexes-of-where-a-string-was-split
        def split_with_offsets(str, r)
          indices = [0]

          str.split("").each_with_index do |char, idx|
            indices << idx if char == r
          end

          indices << str.length

          indices.each_cons(2)
        end
      end
    end
  end
end
