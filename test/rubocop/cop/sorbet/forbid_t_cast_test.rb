# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTCastTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTCast: Do not use `T.cast`."

        def setup
          @cop = ForbidTCast.new
        end

        def test_reports_other_supported_call_forms
          [
            "::T.cast(value, String)",
            "T.cast(value, String, checked: false)",
            "T&.cast(value, String)",
          ].each do |source|
            assert_offense(<<~RUBY)
              #{source}
              #{"^" * source.length} #{MSG}
            RUBY
          end
        end

        def test_ignores_other_receivers
          assert_no_offenses(<<~RUBY)
            Other::T.cast(value, String)
          RUBY
        end

        def test_adds_offense_when_using_t_cast
          assert_offense(<<~RUBY)
            T.cast(foo, String)
            ^^^^^^^^^^^^^^^^^^^ #{MSG}

            x = T.cast(foo, String)
                ^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
