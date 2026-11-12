# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTUnsafeTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTUnsafe: Do not use `T.unsafe`."

        def setup
          @cop = ForbidTUnsafe.new
        end

        def test_reports_other_supported_call_forms
          [
            "::T.unsafe(value)",
            "T&.unsafe(value)",
          ].each do |source|
            assert_offense(<<~RUBY)
              #{source}
              #{"^" * source.length} #{MSG}
            RUBY
          end
        end

        def test_ignores_other_receivers
          assert_no_offenses(<<~RUBY)
            Other::T.unsafe(value)
          RUBY
        end

        def test_adds_offense_when_using_t_unsafe
          assert_offense(<<~RUBY)
            T.unsafe(foo)
            ^^^^^^^^^^^^^ #{MSG}

            x = T.unsafe(foo)
                ^^^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
