# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTUntypedTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTUntyped: Do not use `T.untyped`."

        def setup
          @cop = ForbidTUntyped.new
        end

        def test_adds_offense_for_simple_usage
          assert_offense(<<~RUBY)
            T.untyped
            ^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_adds_offense_when_used_within_type_alias
          assert_offense(<<~RUBY)
            FOO = T.type_alias { T.untyped }
                                 ^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_adds_offense_when_used_within_type_signature
          assert_offense(<<~RUBY)
            sig { params(x: T.untyped).returns(T.untyped) }
                                               ^^^^^^^^^ #{MSG}
                            ^^^^^^^^^ #{MSG}
            def foo(x)
            end
          RUBY
        end

        def test_adds_offense_when_used_within_t_bind
          assert_offense(<<~RUBY)
            def foo(x)
              T.bind(self, T::Array[T.untyped])
                                    ^^^^^^^^^ #{MSG}
            end
          RUBY
        end
      end
    end
  end
end
