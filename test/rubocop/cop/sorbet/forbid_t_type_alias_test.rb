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
