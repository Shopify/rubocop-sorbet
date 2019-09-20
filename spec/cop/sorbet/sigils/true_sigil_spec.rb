# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/sigils/true_sigil'

RSpec.describe(RuboCop::Cop::Sorbet::TrueSigil, :config) do
  subject(:cop) { described_class.new(config) }

  describe('always require a ignore sigil') do
    it 'makes offense if the strictness is not at least `true`' do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # typed: false
        ^^^^^^^^^^^^^^ Sorbet sigil should be at least `true` got `false`.
        class Foo; end
      RUBY
    end

    describe('autocorrect') do
      it('autocorrects by adding typed: true to file without sigil') do
        expect(
          autocorrect_source(<<~RUBY)
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: true
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end
end
