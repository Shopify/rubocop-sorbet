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
