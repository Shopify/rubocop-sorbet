# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class TypeAliasNameTest < ::Minitest::Test
        MSG = "Sorbet/TypeAliasName: Type alias constant name should be in CamelCase"

        def setup
          @cop = TypeAliasName.new
        end

        def test_disallows_naming_a_t_type_alias_constant_in_snake_case
          assert_offense(<<~RUBY)
            A_B = T.type_alias { T.any(A, B) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            A_ = T.type_alias { T.any(A, B) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            A_0 = T.type_alias { T.any(A, B) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            CONSTANT_NAME = T.type_alias { T.any(A, B) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            PARENT::CONSTANT_NAME = T.type_alias { T.any(A, B) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_allows_naming_a_t_type_alias_constant_in_camel_case
          assert_no_offenses(<<~RUBY)
            X = T.type_alias { T.any(A, B) }
            X0 = T.type_alias { X }
            Constant = T.type_alias { Foo }
            ConstantName = T.type_alias { T.any(A, B) }
            HTTP = T.type_alias { Foo }
            PARENT_NAME::ConstantName = T.type_alias { Foo }
          RUBY
        end

        def test_matches_only_t_type_alias_casgn
          assert_no_offenses(<<~RUBY)
            a_or_b = T.type_alias { T.any(A, B) }
            x = T.type_alias { X }
            constant = T.type_alias { Foo }
            constant_name = T.type_alias { T.any(A, B) }
          RUBY
        end
      end
    end
  end
end
