# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidUntypedStructProps, :config) do
  subject(:cop) { described_class.new(config) }

  it "adds offense when const is T.untyped" do
    expect_offense(<<~RUBY)
      class MyClass < T::Struct
        const :foo, T.untyped
                    ^^^^^^^^^ Struct props cannot be T.untyped
      end
    RUBY
  end

  it "adds offense when const is T.nilable(T.untyped)" do
    expect_offense(<<~RUBY)
      class MyClass < T::Struct
        const :foo, T.nilable(T.untyped)
                    ^^^^^^^^^^^^^^^^^^^^ Struct props cannot be T.untyped
      end
    RUBY
  end

  it "adds offense when prop is T.untyped" do
    expect_offense(<<~RUBY)
      class MyClass < T::Struct
        prop :foo, T.untyped
                   ^^^^^^^^^ Struct props cannot be T.untyped
      end
    RUBY
  end

  it "adds offense when prop is T.nilable(T.untyped)" do
    expect_offense(<<~RUBY)
      class MyClass < T::Struct
        prop :foo, T.nilable(T.untyped)
                   ^^^^^^^^^^^^^^^^^^^^ Struct props cannot be T.untyped
      end
    RUBY
  end

  it "adds offense when prop is T.nilable(T.untyped) and has other options" do
    expect_offense(<<~RUBY)
      class MyClass < T::Struct
        prop :foo, T.nilable(T.untyped), immutable: true
                   ^^^^^^^^^^^^^^^^^^^^ Struct props cannot be T.untyped
      end
    RUBY
  end

  it "adds offense when multiple props are untyped" do
    expect_offense(<<~RUBY)
      class MyClass < T::Struct
        const :foo, T.untyped
                    ^^^^^^^^^ Struct props cannot be T.untyped
        const :nilable_foo, T.nilable(T.untyped)
                            ^^^^^^^^^^^^^^^^^^^^ Struct props cannot be T.untyped
        const :nested_foo, T.nilable(T.nilable(T.untyped))
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Struct props cannot be T.untyped
        prop :bar, T.untyped
                   ^^^^^^^^^ Struct props cannot be T.untyped
        prop :nilable_bar, T.nilable(T.untyped)
                           ^^^^^^^^^^^^^^^^^^^^ Struct props cannot be T.untyped
      end
    RUBY
  end

  it "does not add offense when class is not subclass of T::Struct" do
    expect_no_offenses(<<~RUBY)
      class MyClass < SomethingElse
        const :foo, Integer
        const :nilable_foo, T.nilable(String)
        prop :bar, Date
        prop :nilable_bar, T.nilable(Float)
      end
    RUBY
  end

  it "does not add offense when props have types" do
    expect_no_offenses(<<~RUBY)
      class MyClass < T::Struct
        const :foo, Integer
        const :nilable_foo, T.nilable(String)
        prop :bar, Date
        prop :nilable_bar, T.nilable(Float)
        const :array, T::Array[T.untyped]
        const :hash, T::Hash[T.untyped, T.untyped]
      end
    RUBY
  end
end
