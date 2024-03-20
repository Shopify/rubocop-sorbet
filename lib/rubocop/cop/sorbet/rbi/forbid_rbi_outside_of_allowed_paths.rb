# frozen_string_literal: true

require "pathname"

module RuboCop
  module Cop
    module Sorbet
      # Makes sure that RBI files are always located under the defined allowed paths.
      #
      # Options:
      #
      # * `AllowedPaths`: A list of the paths where RBI files are allowed (default: ["rbi/**", "sorbet/rbi/**"])
      #
      # @example
      #   # bad
      #   # lib/some_file.rbi
      #   # other_file.rbi
      #
      #   # good
      #   # rbi/external_interface.rbi
      #   # sorbet/rbi/some_file.rbi
      #   # sorbet/rbi/any/path/for/file.rbi
      class ForbidRBIOutsideOfAllowedPaths < RuboCop::Cop::Base
        include RangeHelp

        MSG = "RBI file path should match one of: %<allowed_paths>s"

        def on_new_investigation
          paths = allowed_paths

          # binding.irb
          first_line_range = source_range(processed_source.buffer, 1, 0)

          if paths.nil?
            add_offense(first_line_range, message: "AllowedPaths expects an array")
            return
          elsif paths.empty?
            add_offense(first_line_range, message: "AllowedPaths cannot be empty")
            return
          end

          # When executed the path to the source file is absolute.
          # We need to remove the exec path directory prefix before matching with the filename regular expressions.
          rel_path = processed_source.file_path.sub("#{Dir.pwd}/", "")
          return if paths.any? { |pattern| File.fnmatch(pattern, rel_path) }

          add_offense(first_line_range, message: format(MSG, allowed_paths: paths.join(", ")))
        end

        private

        def allowed_paths
          paths = cop_config["AllowedPaths"]
          return unless paths.is_a?(Array)

          paths.compact
        end
      end
    end
  end
end
