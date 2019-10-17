# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/signatures/checked_true_in_signature'

RSpec.describe(RuboCop::Cop::Sorbet::CheckedTrueInSignature, :config) do
  subject(:cop) { described_class.new(config) }

  def message
    'Using `checked(true)` in a method signature definition is not allowed. ' \
      '`checked(true)` is the default behavior for modules/classes with runtime checks enabled. ' \
      'To enable typechecking at runtime for this module, regardless of global settings, ' \
      '`include(WaffleCone::RuntimeChecks)` to this module and set other methods to `checked(false)`.'
  end

  describe('offenses') do
    it('disallows using sig.checked(true)') do
      expect_offense(<<~RUBY)
        sig { params(a: Integer).void.checked(true) }
                                      ^^^^^^^^^^^^^ #{message}
        def foo(a); end
      RUBY
    end

    it('allows using checked(false)') do
      expect_no_offenses(<<~RUBY)
        sig { params(a: Integer).void.checked(false) }
        def foo(a); end
      RUBY
    end
  end
end
