# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidTypeAliasedShapes, :config) do
  def message
    "Type aliases shouldn't contain shapes because of significant performance overhead"
  end

  it("allows defining type aliases that don't contain shapes") do
    expect_no_offenses(<<~RUBY)
      Foo = T.type_alias { Integer }
    RUBY
  end

  it("disallows defining type aliases that contain shapes") do
    expect_offense(<<~RUBY)
      Foo = T.type_alias { { foo: Integer } }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
    RUBY
  end

  it("disallows defining type aliases that contain nested shapes") do
    expect_offense(<<~RUBY)
      Foo = T.type_alias { [{ foo: Integer }] }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
    RUBY
  end
end
