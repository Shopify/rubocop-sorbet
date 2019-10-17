# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/signatures/signature_build_order'

RSpec.describe(RuboCop::Cop::Sorbet::SignatureBuildOrder, :config) do
  subject(:cop) { described_class.new(config) }

  describe('offenses') do
    it('allows the correct order') do
      expect_no_offenses(<<~RUBY)
        sig { params(x: Integer).returns(Integer).abstract }

        sig { params(x: Integer).void }

        sig { void.abstract }

        sig { void.implementation.soft }

        sig { void.override.checked(false) }

        sig { void.overridable }
      RUBY
    end

    it('allows using multiline sigs') do
      expect_no_offenses(<<~RUBY)
        sig do
          params(x: Integer)
            .returns(Integer)
            .abstract
        end
      RUBY
    end

    it('enforces orders of builder calls') do
      message = 'Sig builders must be invoked in the following order: type_parameters, params, void.'
      expect_offense(<<~RUBY)
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    end
  end

  describe('autocorrect') do
    it('autocorrects sigs in the correct order') do
      source = <<~RUBY
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          sig { type_parameters(:U).params(x: T.type_parameter(:U)).void }
        RUBY
    end
  end

  describe('without the unparser gem') do
    it('catches the errors and suggests using Unparser for the correction') do
      original_unparser = Unparser
      Object.send(:remove_const, :Unparser) # What does "constant" even mean?
      message =
        'Sig builders must be invoked in the following order: type_parameters, params, void. ' \
        'For autocorrection, add the `unparser` gem to your project.'

      expect_offense(<<~RUBY)
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    ensure
      Object.const_set(:Unparser, original_unparser)
    end
  end
end
