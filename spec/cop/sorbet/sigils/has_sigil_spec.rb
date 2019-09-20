# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/sigils/has_sigil'

RSpec.describe(RuboCop::Cop::Sorbet::HasSigil, :config) do
  subject(:cop) { described_class.new(config) }

  shared_examples_for 'offense for an invalid sigil' do
    it 'enforces that the Sorbet sigil must not be empty' do
      expect_offense(<<~RUBY)
        # Hello world!
        # typed:
        ^^^^^^^^ Sorbet sigil should not be empty.
        class Foo; end
      RUBY
    end

    it 'enforces that the Sorbet sigil must be a valid strictness' do
      expect_offense(<<~RUBY)
        # Hello world!
        # typed: foobar
        ^^^^^^^^^^^^^^^ Invalid Sorbet sigil `foobar`.
        class Foo; end
      RUBY
    end
  end

  shared_examples_for 'no autocorrect on files with sigil' do
    it('does not change files with a sigil') do
      expect(
        autocorrect_source(<<~RUBY)
          # frozen_string_literal: true
          # typed: strict
          class Foo; end
        RUBY
      )
        .to(eq(<<~RUBY))
          # frozen_string_literal: true
          # typed: strict
          class Foo; end
        RUBY
    end

    it('does not change files with an invalid sigil') do
      expect(
        autocorrect_source(<<~RUBY)
          # frozen_string_literal: true
          # typed: no
          class Foo; end
        RUBY
      )
        .to(eq(<<~RUBY))
          # frozen_string_literal: true
          # typed: no
          class Foo; end
        RUBY
    end
  end

  describe('always require a sigil') do
    it_should_behave_like 'offense for an invalid sigil'

    it 'enforces that the sigil must be at the beginning of the file' do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: false` to start (you can also use `rubocop -a` to automatically add this).
        SOMETHING = <<~FOO
          # typed: true
        FOO
      RUBY
    end

    it 'allows Sorbet sigil' do
      expect_no_offenses(<<~RUBY)
        # typed: true
        class Foo; end
      RUBY
    end

    it 'allows empty spaces at the beginning of the file' do
      expect_no_offenses(<<~RUBY)

        # typed: true
        class Foo; end
      RUBY
    end

    describe('autocorrect') do
      it_should_behave_like 'no autocorrect on files with sigil'

      it('autocorrects by adding typed: false to file without sigil') do
        expect(
          autocorrect_source(<<~RUBY)
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: false
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end
end
