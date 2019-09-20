# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/sigils/ignore_sigil'

RSpec.describe(RuboCop::Cop::Sorbet::IgnoreSigil, :config) do
  subject(:cop) { described_class.new(config) }

  describe('always require a ignore sigil') do
    it 'makes offense if the strictness is not at least `ignore`' do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: ignore` to start (you can also use `rubocop -a` to automatically add this).
        class Foo; end
      RUBY
    end

    describe('autocorrect') do
      it('autocorrects by adding typed: ignore to file without sigil') do
        expect(
          autocorrect_source(<<~RUBY)
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: ignore
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end
end
