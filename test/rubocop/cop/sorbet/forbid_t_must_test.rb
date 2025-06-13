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
