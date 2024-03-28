# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::KeywordArgumentOrdering, :config) do
  it("adds offense when optional arguments are at the end") do
    expect_offense(<<~RUBY)
      sig { params(a: Integer, b: String, blk: Proc).void }
      def foo(a: 1, b:, &blk); end
              ^^^^ Optional keyword arguments must be at the end of the parameter list.
    RUBY

    expect_correction(<<~RUBY)
      sig { params(a: Integer, b: String, blk: Proc).void }
      def foo(b:, a: 1, &blk); end
    RUBY
  end

  it("does not add offense when order is correct") do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String, b: Integer, c: Integer, blk: Proc).void }
      def foo(a, b:, c: 10, &blk); end
    RUBY
  end

  it("does not add offense there are no parameters") do
    expect_no_offenses(<<~RUBY)
      sig { void }
      def foo; end
    RUBY
  end

  it("does not add offense when splats are after keyword parameters") do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String, b: Integer, c: String, d: Integer).void }
      def foo(a, b:, c:, **d); end
    RUBY
  end

  it("does not add offense when splats are after optional keyword parameters") do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String, b: Integer, c: String, d: Integer).void }
      def foo(a, b: 1, c: 'a', **d); end
    RUBY
  end

  it("does not add offense when there is only a splat") do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String).void }
      def foo(**a); end
    RUBY
  end

  it("does not add offense when there is a splat after a standard parameter") do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String, b: Integer).void }
      def foo(a, **b); end
    RUBY
  end

  it("adds offense when optional arguments are after default ones and there is a splat") do
    expect_offense(<<~RUBY)
      sig { params(a: String, b: Integer, c: String, d: Integer).void }
      def foo(a, b: 1, c:, **d); end
                 ^^^^ Optional keyword arguments must be at the end of the parameter list.
    RUBY

    expect_correction(<<~RUBY)
      sig { params(a: String, b: Integer, c: String, d: Integer).void }
      def foo(a, c:, b: 1, **d); end
    RUBY
  end

  it "adds offense on offending singleton methods" do
    expect_offense(<<~RUBY)
      sig { params(a: Integer, b: String, blk: Proc).void }
      def self.foo(a: 1, b:, &blk); end
                   ^^^^ Optional keyword arguments must be at the end of the parameter list.
    RUBY

    expect_correction(<<~RUBY)
      sig { params(a: Integer, b: String, blk: Proc).void }
      def self.foo(b:, a: 1, &blk); end
    RUBY
  end

  it "adds offenses when optionality flip flops" do
    expect_offense(<<~RUBY)
      sig { params(a: Integer, b: String, c: Integer, d: String, e: Integer).void }
      def foo(a:, b: 1, c:, d: 3, e:); end
                  ^^^^ Optional keyword arguments must be at the end of the parameter list.
                            ^^^^ Optional keyword arguments must be at the end of the parameter list.
    RUBY

    expect_correction(<<~RUBY)
      sig { params(a: Integer, b: String, c: Integer, d: String, e: Integer).void }
      def foo(a:, c:, e:, b: 1, d: 3); end
    RUBY
  end
end
