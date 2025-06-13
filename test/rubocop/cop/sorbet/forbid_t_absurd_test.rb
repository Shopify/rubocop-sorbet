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
