# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks that any "and" version annotations don't exclude all versions
      #
      # @example
      #   # bad
      #   # @version < 2, > 5
      #
      #   # good
      #   # @version > 2, < 5
      #
      class ForbidFalsyAndAnnotaitons < Base
        include GemVersionAnnotationHelper

        MSG = "Annotation excludes all versions"

        def on_new_investigation
          return if gem_version_annotations.empty?

          gem_version_annotations.each do |comment|
            gem_versions = gem_versions(comment)

            next if gem_versions.length <= 1

            ranges = gem_versions.map { |version| version_to_ranges(version) }.flatten

            all_overlap = ranges.combination(2).all? do |first, second|
              first.overlap?(second)
            end

            add_offense(comment) unless all_overlap
          end
        end

        private

        def version_to_ranges(version_string)
          parts = version_string.strip.split(" ")
          operator, version = parts

          if operator == "!="
            [
              GemRange.from_version_string("< #{version}"),
              GemRange.from_version_string("> #{version}"),
            ]
          else
            [GemRange.from_version_string(version_string)]
          end
        end
      end
    end
  end
end
