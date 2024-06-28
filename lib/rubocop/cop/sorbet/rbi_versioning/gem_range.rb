# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      class GemRange < ::Range
        def overlap?(other)
          raise ArgumentError unless other.is_a?(GemRange)

          cover?(other.begin) || other.cover?(self.begin)
        end

        class << self
          def from_version_string(version_string)
            parts = version_string.strip.split(" ")
            operator, version = parts

            raise ArgumentError if operator.nil? || version.nil?
            raise ArgumentError unless Gem::Version.correct?(version)

            gem_version = ::Gem::Version.new(version)

            case operator
            when "="
              new(gem_version, gem_version)
            when "<"
              new(nil, gem_version, true)
            when "<="
              new(nil, gem_version)
            when "~>"
              new(gem_version, gem_version.bump, true)
            when ">="
              new(gem_version, nil)
            when ">"
              # This is not strictly accurate... find a better way?
              next_version = ::Gem::Version.new(gem_version.to_s + ".1")
              new(next_version, nil)
            end
          end
        end
      end
    end
  end
end
