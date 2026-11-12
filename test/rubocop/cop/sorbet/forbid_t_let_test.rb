# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTLetTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTLet: Do not use `T.let`."

        def setup
          @cop = ForbidTLet.new
        end

        def test_reports_other_supported_call_forms
          [
            "::T.let(value, String)",
            "T.let(value, String, checked: false)",
            "T&.let(value, String)",
          ].each do |source|
            assert_offense(<<~RUBY)
              #{source}
              #{"^" * source.length} #{MSG}
            RUBY
          end
        end

        def test_ignores_other_receivers
          assert_no_offenses(<<~RUBY)
            Other::T.let(value, String)
          RUBY
        end

        def test_adds_offense_when_using_t_let
          assert_offense(<<~RUBY)
            T.let(foo, String)
            ^^^^^^^^^^^^^^^^^^ #{MSG}

            x = T.let(foo, String)
                ^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
