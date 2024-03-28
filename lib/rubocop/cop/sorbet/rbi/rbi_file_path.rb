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
      class RBIFilePath < RuboCop::Cop::Base
        MSG = "RBI file path should match one of: %<allowed_paths>s"

        def on_new_investigation
          allowed_paths = cop_config.fetch("AllowedPaths")

          # When executed the path to the source file is absolute.
          # We need to remove the exec path directory prefix before matching with the filename regular expressions.
          rel_path = processed_source.file_path.sub("#{Dir.pwd}/", "")
          return if allowed_paths.any? { |pattern| File.fnmatch(pattern, rel_path) }

          add_global_offense(format(MSG, allowed_paths: allowed_paths.join(", ")))
        end
      end
    end
  end
end
