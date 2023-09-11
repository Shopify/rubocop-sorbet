# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidTStruct, :config) do
  it "adds offense when using T::Struct" do
    expect_offense(<<~RUBY)
      class Foo < T::Struct
      ^^^^^^^^^^^^^^^^^^^^^ Do not use `T::Struct`.
        prop :bar, T.nilable(String)
        const :baz, Integer
      end

      class Foo < T::Struct; end
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use `T::Struct`.
    RUBY
  end

  it "does not add offense when not using T::Struct" do
    expect_no_offenses(<<~RUBY)
      class Foo
        extend T::Sig

        sig { returns(T.nilable(String)) }
        attr_accessor :bar

        sig { returns(Integer) }
        attr_reader :baz
      end

      class Bar < Baz; end
    RUBY
  end
end
