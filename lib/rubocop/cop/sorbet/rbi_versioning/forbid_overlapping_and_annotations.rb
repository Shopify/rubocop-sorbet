# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks that RBI gem version annotations do not contain "and" statements with
      # overlapping gem versions.
      #
      # @example
      #   # bad
      #   # @version > 3.2.3, > 4.5
      #
      #   # bad
      #   # @version > 1.0, <= 2.0, = 1.5
      #
      #   # good
      #   # @version < 1.0, >= 2.0
      #
      class ForbidOverlappingAndAnnotations < Base
        include RBIVersionAnnotationHelper

        MSG = "Some message here"

        def on_new_investigation
          rbi_version_annotations.each do |comment|
            ranges = []
            versions(comment).each do |version|
              ranges += version_to_ranges(version)
            end

            overlap = ranges.combination(2).any? do |range_1, range_2|
              range_1.cover?(range_2) || range_2.cover?(range_1)
            end

            add_offense(comment) if overlap
          end
        end

        private

        def version_to_ranges(version_string)
          operator, version = version_string.strip.split(" ")
          # TODO: make more specific
          raise if operator.nil? || version.nil?

          begin
            gem_version = Gem::Version.new(version)
          rescue ArgumentError
            # TODO: do something here
            return
          end

          case operator
          when "="
            [Range.new(gem_version, gem_version)]
          when "!="
            prev_version_down = Gem::Version.new(gem_version.to_s + "-pre")
            next_version_up = Gem::Version.new(gem_version.to_s + ".1")
            [Range.new(nil, prev_version_down), Range.new(next_version_up, nil)]
          when ">"
            next_version_up = Gem::Version.new(gem_version.to_s + ".1")
            [Range.new(next_version_up, nil)]
          when ">="
            [Range.new(gem_version, nil)]
          when "<"
            [Range.new(nil, gem_version, true)] # exclude ending value
          when "<="
            [Range.new(nil, gem_version)] # include ending value
          when "~>"
            [Range.new(gem_version, gem_version.bump)]
          else
            # TODO: make more specific
            raise "INVALID OPERATOR"
          end
        end
      end
    end
  end
end
