# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::ForbidComparableTEnum, :config) do
  it "registers an offense when T::Enum includes Comparable" do
    expect_offense(<<~RUBY)
      class MyEnum < T::Enum
        include Comparable
        ^^^^^^^^^^^^^^^^^^ Do not use `T::Enum` as a comparable object because of significant performance overhead.
      end
    RUBY
  end

  it "registers an offense when T::Enum prepends Comparable" do
    expect_offense(<<~RUBY)
      class MyEnum < T::Enum
        prepend Comparable
        ^^^^^^^^^^^^^^^^^^ Do not use `T::Enum` as a comparable object because of significant performance overhead.
      end
    RUBY
  end

  it "does not register an offense when T::Enum includes other modules" do
    expect_no_offenses(<<~RUBY)
      class MyEnum < T::Enum
        include T::Sig
      end
    RUBY
  end

  it "does not register an offense when T::Enum includes no other modules" do
    expect_no_offenses(<<~RUBY)
      class MyEnum < T::Enum; end
    RUBY
  end

  it "does not register an offense when Comparable is included in a nested, non T::Enum class" do
    expect_no_offenses(<<~RUBY)
      class MyEnum < T::Enum
        class Foo
          include Comparable
        end
      end
    RUBY
  end

  it "does not register an offense when Comparable is prepended in a nested, non T::Enum class" do
    expect_no_offenses(<<~RUBY)
      class MyEnum < T::Enum
        class Foo
          prepend Comparable
        end
      end
    RUBY
  end
end
