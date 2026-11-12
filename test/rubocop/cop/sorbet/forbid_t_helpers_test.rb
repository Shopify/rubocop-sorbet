# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTHelpersTest < ::Minitest::Test
        def setup
          @cop = ForbidTHelpers.new
        end

        def test_reports_the_helper_among_multiple_modules
          [
            "extend Other, ::T::Helpers, Another",
            "include T::Helpers, Other",
            "self&.extend Other, T::Helpers",
          ].each do |source|
            method = source.include?("include") ? "include" : "extend"
            assert_offense(<<~RUBY)
              #{source}
              #{"^" * source.length} Sorbet/ForbidTHelpers: Do not use `#{method} T::Helpers`.
            RUBY
          end
        end

        def test_adds_offense_when_extending_t_helpers
          assert_offense(<<~RUBY)
            class Example
              extend T::Helpers
              ^^^^^^^^^^^^^^^^^ Sorbet/ForbidTHelpers: Do not use `extend T::Helpers`.
            end
          RUBY
        end

        def test_adds_offense_when_including_t_helpers
          assert_offense(<<~RUBY)
            class Example
              include T::Helpers
              ^^^^^^^^^^^^^^^^^^ Sorbet/ForbidTHelpers: Do not use `include T::Helpers`.
            end
          RUBY
        end

        def test_adds_offense_when_extending_t_helpers_in_module
          assert_offense(<<~RUBY)
            module Example
              extend T::Helpers
              ^^^^^^^^^^^^^^^^^ Sorbet/ForbidTHelpers: Do not use `extend T::Helpers`.
            end
          RUBY
        end

        def test_adds_offense_when_extending_t_helpers_with_cbase
          assert_offense(<<~RUBY)
            class Example
              extend ::T::Helpers
              ^^^^^^^^^^^^^^^^^^^ Sorbet/ForbidTHelpers: Do not use `extend T::Helpers`.
            end
          RUBY
        end

        def test_no_offense_when_not_using_t_helpers
          assert_no_offenses(<<~RUBY)
            class Example
            end
          RUBY
        end

        def test_no_offense_when_extending_other_modules
          assert_no_offenses(<<~RUBY)
            class Example
              extend ActiveSupport::Concern
            end
          RUBY
        end

        def test_no_offense_when_extending_t_sig
          assert_no_offenses(<<~RUBY)
            class Example
              extend T::Sig
            end
          RUBY
        end
      end
    end
  end
end
