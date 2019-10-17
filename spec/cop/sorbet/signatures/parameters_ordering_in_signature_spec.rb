# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/signatures/parameters_ordering_in_signature'

RSpec.describe(RuboCop::Cop::Sorbet::ParametersOrderingInSignature, :config) do
  subject(:cop) { described_class.new(config) }

  it('adds offense when ordering of parameters is inconsistent in keyword arguments') do
    expect_offense(<<~RUBY)
      sig { params(b: String, a: Integer).void }
      def foo(a:, b:); end
                  ^^ Inconsistent ordering of arguments at index 1. Expected `a` from sig above.
              ^^ Inconsistent ordering of arguments at index 0. Expected `b` from sig above.
    RUBY
  end

  it('adds offense when ordering of parameters is inconsistent') do
    expect_offense(<<~RUBY)
      sig do
        returns(String).params(b: String, a: Integer, c: T::Boolean)
      end
      def foo(a, b:, c:); end
                 ^^ Inconsistent ordering of arguments at index 1. Expected `a` from sig above.
              ^ Inconsistent ordering of arguments at index 0. Expected `b` from sig above.
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

  it('does not add offense for attr_reader') do
    expect_no_offenses(<<~RUBY)
      sig { returns(Integer) }
      attr_reader :foo
    RUBY
  end
end
