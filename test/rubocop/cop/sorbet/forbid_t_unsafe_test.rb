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

        def test_adds_offense_when_using_t_unsafe
          assert_offense(<<~RUBY)
            T.unsafe(foo)
            ^^^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
