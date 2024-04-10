# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::ForbidSingleValueTEnum, :config) do
  it "registers an offense when creating a T::Enum with one value" do
    expect_offense(<<~RUBY)
      class MyEnum < T::Enum
        enums do
        ^^^^^^^^ `T::Enum` should have at least two values.
          A = new
        end
      end
    RUBY
  end

  it "does not register an offense when creating a T::Enum with two values" do
    expect_no_offenses(<<~RUBY)
      class MyEnum < T::Enum
        enums do
          A = new
          B = new
        end
      end
    RUBY
  end
end
