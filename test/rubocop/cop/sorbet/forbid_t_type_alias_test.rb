# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTTypeAliasTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTTypeAlias: Do not use `T.type_alias`."

        def setup
          @cop = ForbidTTypeAlias.new
        end

        def test_reports_other_supported_call_forms
          [
            "Alias = ::T.type_alias { String }",
            "Alias = T.type_alias(String)",
            "Alias = T&.type_alias { String }",
          ].each do |source|
            assert_offense(<<~RUBY)
              #{source}
              #{" " * 8}#{"^" * (source.length - 8)} #{MSG}
            RUBY
          end
        end

        def test_ignores_other_receivers
          assert_no_offenses(<<~RUBY)
            Other::T.type_alias { String }
          RUBY
        end

        def test_adds_offense_when_using_t_type_alias
          assert_offense(<<~RUBY)
            X = T.type_alias { T.any(String, Integer) }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
