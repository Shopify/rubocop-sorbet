# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/signatures/keyword_argument_ordering'

RSpec.describe(RuboCop::Cop::Sorbet::KeywordArgumentOrdering, :config) do
  subject(:cop) { described_class.new(config) }

  it('adds offense when optional arguments are at the end') do
    expect_offense(<<~RUBY)
      sig { params(a: Integer, b: String, blk: Proc).void }
      def foo(a: 1, b:, &blk); end
              ^^^^ Optional keyword arguments must be at the end of the parameter list.
    RUBY
  end

  it('does not add offense when order is correct') do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String, b: Integer, c: Integer, blk: Proc).void }
      def foo(a, b:, c: 10, &blk); end
    RUBY
  end

  it('does not add offense there are no parameters') do
    expect_no_offenses(<<~RUBY)
      sig { void }
      def foo; end
    RUBY
  end

  it('does not add offense when splats are after keyword parameters') do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String, b: Integer, c: String, d: Integer).void }
      def foo(a, b:, c:, **d); end
    RUBY
  end

  it('does not add offense when splats are after optional keyword parameters') do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String, b: Integer, c: String, d: Integer).void }
      def foo(a, b: 1, c: 'a', **d); end
    RUBY
  end

  it('does not add offense when there is only a splat') do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String).void }
      def foo(**a); end
    RUBY
  end

  it('does not add offense when there is a splat after a standard parameter') do
    expect_no_offenses(<<~RUBY)
      sig { params(a: String, b: Integer).void }
      def foo(a, **b); end
    RUBY
  end

  it('adds offense when optional arguments are after default ones and there is a splat') do
    expect_offense(<<~RUBY)
      sig { params(a: String, b: Integer, c: String, d: Integer).void }
      def foo(a, b: 1, c:, **d); end
                 ^^^^ Optional keyword arguments must be at the end of the parameter list.
    RUBY
  end
end
