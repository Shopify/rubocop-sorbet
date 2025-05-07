# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module RbiVersioning
        class ValidGemVersionAnnotationsTest < ::Minitest::Test
          MSG = "Sorbet/ValidGemVersionAnnotations: Invalid gem version(s) detected: %{message}"

          def setup
            @cop = ValidGemVersionAnnotations.new
          end

          def test_does_not_register_offense_when_comment_is_not_version_annotation
            assert_no_offenses(<<~RUBY)
              # a random comment
            RUBY
          end

          def test_does_not_register_offense_when_comment_is_valid_version_annotation
            assert_no_offenses(<<~RUBY)
              # @version = 1.3.4-prerelease
            RUBY
          end

          def test_does_not_register_offense_when_comment_uses_and_version_annotations
            assert_no_offenses(<<~RUBY)
              # @version > 1, < 3.5
            RUBY
          end

          def test_does_not_register_offense_when_comment_uses_or_version_annotations
            assert_no_offenses(<<~RUBY)
              # @version > 1.3.6
              # @version <= 4
            RUBY
          end

          def test_registers_offense_for_empty_version_annotation
            assert_offense(<<~RUBY)
              # @version
              ^^^^^^^^^^ #{format(MSG, message: "empty version")}
            RUBY
          end

          def test_registers_offense_for_annotation_with_no_operator
            assert_offense(<<~RUBY)
              # @version blah
              ^^^^^^^^^^^^^^^ #{format(MSG, message: "blah")}
            RUBY
          end

          def test_registers_offense_when_gem_version_is_not_formatted_correctly
            assert_offense(<<~RUBY)
              # @version = blah
              ^^^^^^^^^^^^^^^^^ #{format(MSG, message: "= blah")}
            RUBY
          end

          def test_registers_offense_when_one_gem_version_out_of_list_is_not_formatted_correctly
            assert_offense(<<~RUBY)
              # @version < 3.2, > 4, ~> five
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, message: "~> five")}
            RUBY
          end

          def test_registers_offense_when_one_gem_version_is_not_formatted_correctly_in_or
            assert_offense(<<~RUBY)
              # @version < 3.2, > 4
              # @version ~> five
              ^^^^^^^^^^^^^^^^^^ #{format(MSG, message: "~> five")}
            RUBY
          end

          def test_registers_offense_for_multiple_incorrectly_formatted_versions
            assert_offense(<<~RUBY)
              # @version < 3.2, ~> five, = blah
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, message: "~> five, = blah")}
            RUBY
          end

          def test_registers_offense_if_operator_is_invalid
            assert_offense(<<~RUBY)
              # @version << 3.2
              ^^^^^^^^^^^^^^^^^ #{format(MSG, message: "<< 3.2")}
            RUBY
          end
        end
      end
    end
  end
end
