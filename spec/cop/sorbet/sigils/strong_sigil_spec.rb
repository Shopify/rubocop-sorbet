# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/sigils/strong_sigil'

RSpec.describe(RuboCop::Cop::Sorbet::StrongSigil, :config) do
  subject(:cop) { described_class.new(config) }

  describe('always require a ignore sigil') do
    it 'makes offense if the strongness is not at least `strong`' do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # typed: strict
        ^^^^^^^^^^^^^^^ Sorbet sigil should be at least `strong` got `strict`.
        class Foo; end
      RUBY
    end

    describe('autocorrect') do
      it('autocorrects by adding typed: strong to file without sigil') do
        expect(
          autocorrect_source(<<~RUBY)
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: strong
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end
end
