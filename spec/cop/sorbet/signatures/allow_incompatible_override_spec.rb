# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/signatures/allow_incompatible_override'

RSpec.describe(RuboCop::Cop::Sorbet::AllowIncompatibleOverride, :config) do
  subject(:cop) { described_class.new(config) }

  def message
    'Usage of `allow_incompatible` suggests a violation of the Liskov Substitution Principle. '\
    'Instead, strive to write interfaces which respect subtyping principles and remove `allow_incompatible`'
  end

  it('disallows using override(allow_incompatible: true)') do
    expect_offense(<<~RUBY)
      class Foo
        sig(a: Integer).override(allow_incompatible: true).void
                                 ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it('allows override without allow_incompatible') do
    expect_no_offenses(<<~RUBY)
      class Foo
        sig(a: Integer).void.override
      end
    RUBY
  end
end
