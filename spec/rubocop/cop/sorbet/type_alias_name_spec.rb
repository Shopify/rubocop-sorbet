# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::TypeAliasName, :config) do
  MSG = "Type alias constant name should be in CamelCase"

  describe("offenses") do
    it("disallows naming a T.type_alias constant in snake_case") do
      expect_offense(<<~RUBY)
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

    it("allows naming a T.type_alias constant in CamelCase") do
      expect_no_offenses(<<~RUBY)
        X = T.type_alias { T.any(A, B) }
        X0 = T.type_alias { X }
        Constant = T.type_alias { Foo }
        ConstantName = T.type_alias { T.any(A, B) }
        HTTP = T.type_alias { Foo }
        PARENT_NAME::ConstantName = T.type_alias { Foo }
      RUBY
    end

    it("matches only T.type_alias casgn") do
      expect_no_offenses(<<~RUBY)
        a_or_b = T.type_alias { T.any(A, B) }
        x = T.type_alias { X }
        constant = T.type_alias { Foo }
        constant_name = T.type_alias { T.any(A, B) }
      RUBY
    end
  end
end
