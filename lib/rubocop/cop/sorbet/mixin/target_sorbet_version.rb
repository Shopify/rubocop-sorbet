# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      module TargetSorbetVersion
        def self.included(target)
          target.extend(ClassMethods)
        end

        module ClassMethods
          # The version of the Sorbet static type checker required by this cop
          def minimum_target_sorbet_static_version(version)
            @minimum_target_sorbet_static_version = Gem::Version.new(version)
          end

          def support_target_sorbet_static_version?(version)
            @minimum_target_sorbet_static_version <= Gem::Version.new(version)
          end
        end

        def enabled_for_sorbet_static_version?
          sorbet_static_version = target_sorbet_static_version_from_bundler_lock_file
          return false unless sorbet_static_version

          self.class.support_target_sorbet_static_version?(sorbet_static_version)
        end

        def target_sorbet_static_version_from_bundler_lock_file
          @target_sorbet_static_version_from_bundler_lock_file ||= read_sorbet_static_version_from_bundler_lock_file
        end

        # Adapted from https://github.com/rubocop/rubocop/blob/1181d4ebad5f71c586f9514d9c341cdfffc1957d/lib/rubocop/config.rb#L293-L308
        def read_sorbet_static_version_from_bundler_lock_file
          lock_file_path = config.bundler_lock_file_path

          return nil unless lock_file_path

          File.foreach(lock_file_path) do |line|
            # If Sorbet (or one of its frameworks) is in Gemfile.lock or gems.lock, there should be
            # a line like:
            #         sorbet-static (X.X.X-some_arch)
            result = line.match(/^\s+sorbet-static\s+\((\d+\.\d+\.\d+)/)
            return Gem::Version.new(result.captures.first) if result
          end
        end
      end
    end
  end
end
