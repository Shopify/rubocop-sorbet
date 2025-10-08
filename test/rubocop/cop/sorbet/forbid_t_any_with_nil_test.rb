# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTAnyWithNilTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTAnyWithNil: Use `T.nilable` instead of `T.any(..., NilClass, ...)`."

        def setup
          @cop = ForbidTAnyWithNil.new
        end

        def test_registers_offense_when_t_any_with_two_arguments_is_used
          assert_offense(<<~RUBY)
            T.any(NilClass, String)
            ^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            T.nilable(String)
          RUBY
        end

        def test_registers_offense_when_t_any_with_many_arguments_is_used
          assert_offense(<<~RUBY)
            T.any(Symbol, NilClass, String)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            T.nilable(T.any(Symbol, String))
          RUBY
        end

        def test_does_not_register_offense_when_t_nilable_is_used
          assert_no_offenses(<<~RUBY)
            T.nilable(String)
          RUBY
        end
      end
    end
  end
end
