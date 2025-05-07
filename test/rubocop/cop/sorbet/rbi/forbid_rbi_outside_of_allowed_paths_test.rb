# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Rbi
        class ForbidRBIOutsideOfAllowedPathsTest < ::Minitest::Test
          MSG = "RBI file path should match one of: rbi/**, sorbet/rbi/**"

          def setup
            @cop = target_cop.new(cop_config)
          end

          def test_registers_offense_when_rbi_file_is_outside_of_default_allowed_paths
            assert_offense(<<~RUBY, "some/dir/file.rbi")
              print 1
              ^{} #{MSG}
            RUBY
          end

          def test_registers_offense_when_empty_file_is_outside_of_default_allowed_paths
            assert_offense(<<~RUBY, "some/dir/file.rbi")
              ^{} #{MSG}
            RUBY
          end

          def test_does_not_register_offense_when_rbi_file_is_inside_rbi_directory
            assert_no_offenses(<<~RUBY, "rbi/some/dir/file.rbi")
              print 1
            RUBY
          end

          def test_does_not_register_offense_when_rbi_file_is_inside_sorbet_rbi_directory
            assert_no_offenses(<<~RUBY, "sorbet/rbi/some/dir/file.rbi")
              print 1
            RUBY
          end

          def test_does_not_register_offense_when_rbi_file_has_absolute_path_in_sorbet_rbi
            assert_no_offenses(<<~RUBY, "#{Dir.pwd}/sorbet/rbi/some/dir/file.rbi")
              print 1
            RUBY
          end

          def test_with_custom_allowed_path
            @cop = target_cop.new(cop_config({
              "Enabled" => true,
              "AllowedPaths" => ["some/allowed/**"],
            }))

            assert_offense(<<~RUBY, "some/forbidden/directory/file.rbi")
              print 1
              ^{} RBI file path should match one of: some/allowed/**
            RUBY

            assert_no_offenses(<<~RUBY, "some/allowed/directory/file.rbi")
              print 1
            RUBY

            assert_no_offenses(<<~RUBY, "#{Dir.pwd}/some/allowed/directory/file.rbi")
              print 1
            RUBY
          end

          def test_with_multiple_allowed_paths
            @cop = target_cop.new(cop_config({
              "Enabled" => true,
              "AllowedPaths" => ["some/allowed/**", "hello/other/allowed/**"],
            }))

            assert_no_offenses(<<~RUBY, "hello/other/allowed/file.rbi")
              print 1
            RUBY

            assert_offense(<<~RUBY, "some/forbidden/directory/file.rbi")
              print 1
              ^{} RBI file path should match one of: some/allowed/**, hello/other/allowed/**
            RUBY
          end

          def test_with_empty_allowed_paths
            @cop = target_cop.new(cop_config({
              "Enabled" => true,
              "AllowedPaths" => [],
            }))

            assert_offense(<<~RUBY, "sorbet/rbi/file.rbi")
              print 1
              ^{} AllowedPaths cannot be empty
            RUBY
          end

          def test_with_nil_allowed_paths
            @cop = target_cop.new(cop_config({
              "Enabled" => true,
              "AllowedPaths" => nil,
            }))

            assert_offense(<<~RUBY, "some/directory/file.rbi")
              print 1
              ^{} AllowedPaths expects an array
            RUBY
          end

          def test_with_nil_in_allowed_paths
            @cop = target_cop.new(cop_config({
              "Enabled" => true,
              "AllowedPaths" => [nil],
            }))

            assert_offense(<<~RUBY, "some/directory/file.rbi")
              print 1
              ^{} AllowedPaths cannot be empty
            RUBY
          end

          def test_with_non_array_allowed_paths
            @cop = target_cop.new(cop_config({
              "Enabled" => true,
              "AllowedPaths" => "sorbet/rbi/**",
            }))

            assert_offense(<<~RUBY, "some/directory/file.rbi")
              print 1
              ^{} AllowedPaths expects an array
            RUBY
          end

          private

          def target_cop
            ForbidRBIOutsideOfAllowedPaths
          end
        end
      end
    end
  end
end
