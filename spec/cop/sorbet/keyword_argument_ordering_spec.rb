# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/sorbet/keyword_argument_ordering'

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
end
