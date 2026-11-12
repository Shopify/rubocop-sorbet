# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTMustTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTMust: Do not use `T.must`."

        def setup
          @cop = ForbidTMust.new
        end

        def test_reports_other_supported_call_forms
          [
            "::T.must(value)",
            "T&.must(value)",
          ].each do |source|
            assert_offense(<<~RUBY)
              #{source}
              #{"^" * source.length} #{MSG}
            RUBY
          end
        end

        def test_ignores_other_receivers
          assert_no_offenses(<<~RUBY)
            Other::T.must(value)
          RUBY
        end

        def test_adds_offense_when_using_t_must
          assert_offense(<<~RUBY)
            T.must(foo)
            ^^^^^^^^^^^ #{MSG}

            x = T.must(foo)
                ^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
