# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTCastTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTCast: Do not use `T.cast`."

        def setup
          @cop = ForbidTCast.new
        end

        def test_adds_offense_when_using_t_cast
          assert_offense(<<~RUBY)
            T.cast(foo, String)
            ^^^^^^^^^^^^^^^^^^^ #{MSG}

            x = T.cast(foo, String)
                ^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
