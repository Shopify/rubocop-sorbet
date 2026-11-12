# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTBindTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTBind: Do not use `T.bind`."

        def setup
          @cop = ForbidTBind.new
        end

        def test_reports_other_supported_call_forms
          [
            "::T.bind(self, String)",
            "T.bind(self, String, checked: false)",
            "T&.bind(self, String)",
          ].each do |source|
            assert_offense(<<~RUBY)
              #{source}
              #{"^" * source.length} #{MSG}
            RUBY
          end
        end

        def test_ignores_other_receivers
          assert_no_offenses(<<~RUBY)
            Other::T.bind(value, String)
          RUBY
        end

        def test_adds_offense_when_using_t_bind
          assert_offense(<<~RUBY)
            T.bind(self, String)
            ^^^^^^^^^^^^^^^^^^^^ #{MSG}

            x = T.bind(self, String)
                ^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
