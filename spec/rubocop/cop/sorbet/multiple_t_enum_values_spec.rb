# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::MultipleTEnumValues, :config) do
  it "registers an offense when creating a T::Enum with no values" do
    expect_offense(<<~RUBY)
      class MyEnum < T::Enum
      ^^^^^^^^^^^^^^^^^^^^^^ `T::Enum` should have at least two values.
        enums do
        end
      end
    RUBY
  end

  it "registers an offense when creating a T::Enum with one value" do
    expect_offense(<<~RUBY)
      class MyEnum < T::Enum
      ^^^^^^^^^^^^^^^^^^^^^^ `T::Enum` should have at least two values.
        enums do
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

  it "registers an offense for a nested T::Enum" do
    expect_offense(<<~RUBY)
      class MyEnum < T::Enum
        class NestedEnum < T::Enum
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ `T::Enum` should have at least two values.
          enums do
            A = new
          end
        end

        enums do
          B = new
          C = new
        end
      end
    RUBY
  end

  it "registers an offense for outer T::Enum" do
    expect_offense(<<~RUBY)
      class MyEnum < T::Enum
      ^^^^^^^^^^^^^^^^^^^^^^ `T::Enum` should have at least two values.
        class NestedEnum < T::Enum
          enums do
            A = new
            B = new
          end
        end

        enums do
          C = new
        end
      end
    RUBY
  end

  it "registers an offense for a T::Enum with no `enums` block" do
    expect_offense(<<~RUBY)
      class MyEnum < T::Enum
      ^^^^^^^^^^^^^^^^^^^^^^ `T::Enum` should have at least two values.
      end
    RUBY
  end

  it "does not register an offense for a non-T::Enum class with an enums block" do
    expect_no_offenses(<<~RUBY)
      class MyEnum < T::Enum
        class Foo
          enums do; end
        end
      end
    RUBY
  end
end
