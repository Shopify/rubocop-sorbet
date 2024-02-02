# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks that gem versions in RBI annotations are properly formatted per the Bundler gem specification.
      #
      # @example
      #   # bad
      #   # @version > blah
      #
      #   # good
      #   # @version = 1
      #
      #   # good
      #   # @version > 1.2.3
      #
      #   # good
      #   # @version <= 4.3-preview
      #
      class ValidVersionAnnotations < Base
        include RBIVersionAnnotationHelper

        MSG = "Invalid gem version(s) detected: %<versions>s"

        def on_new_investigation
          rbi_version_annotations.each do |comment|
            invalid_versions = []

            versions.each do |version|
              invalid_versions << version unless valid_version?(version)
            end

            unless invalid_versions.empty?
              message = format(MSG, versions: invalid_versions.join(", "))
              add_offense(comment, message: message)
            end
          end
        end

        private

        def valid_version?(version_string)
          parts = version_string.strip.split(" ")
          return false unless parts.length == 2

          version = parts.last

          begin
            Gem::Version.new(version)
          rescue ArgumentError
            return false
          end

          true
        end
      end
    end
  end
end
