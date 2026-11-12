# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTAbsurdTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTAbsurd: Do not use `T.absurd`."

        def setup
          @cop = ForbidTAbsurd.new
        end

        def test_reports_other_supported_call_forms
          [
            "::T.absurd(value)",
            "T&.absurd(value)",
          ].each do |source|
            assert_offense(<<~RUBY)
              #{source}
              #{"^" * source.length} #{MSG}
            RUBY
          end
        end

        def test_ignores_other_receivers
          assert_no_offenses(<<~RUBY)
            Other::T.absurd(value)
          RUBY
        end

        def test_adds_offense_when_using_t_absurd
          assert_offense(<<~RUBY)
            T.absurd(foo)
            ^^^^^^^^^^^^^ #{MSG}

            x = T.absurd(foo)
                ^^^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
