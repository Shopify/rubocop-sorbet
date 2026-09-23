# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTAssertTypeTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTAssertType: Do not use `T.assert_type!`."

        def setup
          @cop = ForbidTAssertType.new
        end

        def test_adds_offense_for_assert_type
          assert_offense(<<~RUBY)
            T.assert_type!(foo, Integer)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_adds_offense_for_top_level_constant
          assert_offense(<<~RUBY)
            ::T.assert_type!(foo, Integer)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_adds_offense_for_safe_navigation
          assert_offense(<<~RUBY)
            T&.assert_type!(foo, Integer)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_adds_offense_with_runtime_check_disabled
          assert_offense(<<~RUBY)
            T.assert_type!(foo, Integer, checked: false)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_allows_unrelated_receivers
          assert_no_offenses(<<~RUBY)
            assert_type!(foo, Integer)
            other.assert_type!(foo, Integer)
            Other::T.assert_type!(foo, Integer)
          RUBY
        end

        def test_allows_other_sorbet_methods
          assert_no_offenses(<<~RUBY)
            T.let(foo, Integer)
            T.cast(foo, Integer)
          RUBY
        end
      end
    end
  end
end
