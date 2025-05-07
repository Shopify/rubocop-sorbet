# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTypeAliasedShapesTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTypeAliasedShapes: Type aliases shouldn't contain shapes because of significant performance overhead"

        def setup
          @cop = ForbidTypeAliasedShapes.new
        end

        def test_allows_defining_type_aliases_that_dont_contain_shapes
          assert_no_offenses(<<~RUBY)
            Foo = T.type_alias { Integer }
          RUBY
        end

        def test_disallows_defining_type_aliases_that_contain_shapes
          assert_offense(<<~RUBY)
            Foo = T.type_alias { { foo: Integer } }
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_disallows_defining_type_aliases_that_contain_nested_shapes
          assert_offense(<<~RUBY)
            A = T.type_alias { [{ foo: Integer }] }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            B = T.type_alias { T.nilable({ foo: Integer }) }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            C = T.type_alias { T::Hash[Symbol, { foo: Integer }] }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            D = T.type_alias { T::Hash[Symbol, T::Array[T.any(String, { foo: Integer })]] }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
