# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/sigils/enforce_sigil_order'

RSpec.describe(RuboCop::Cop::Sorbet::EnforceSigilOrder, :config) do
  subject(:cop) { described_class.new(config) }

  it('makes no offense on empty files') do
    expect_no_offenses(<<~RUBY)
    RUBY
  end

  it('makes no offense with no magic comments') do
    expect_no_offenses(<<~RUBY)
      class Foo; end
    RUBY
  end

  it('makes no offense with random magic comments') do
    expect_no_offenses(<<~RUBY)
      # foo: 1
      # bar: true
      # baz: "Hello, World"
      class Foo; end
    RUBY
  end

  it('makes no offense with only one magic comment') do
    expect_no_offenses(<<~RUBY)
      # typed: true
      class Foo; end
    RUBY
  end

  it('makes no offense when the magic comments are correctly ordered') do
    expect_no_offenses(<<~RUBY)
      # typed: true
      # encoding: utf-8
      # coding: utf-8
      # warn_indent: true
      # frozen_string_literal: true
      class Foo; end
    RUBY
  end

  it('makes no offense when the magic comments are correctly ordered with random comments in the middle') do
    expect_no_offenses(<<~RUBY)
      # typed: true
      # foo: 1
      # coding: utf-8
      # bar: true
      # frozen_string_literal: true
      # baz: "Hello, World"
      class Foo; end
    RUBY
  end

  it('makes offense when two magic comments are not correctly ordered') do
    expect_offense(<<~RUBY)
      # frozen_string_literal: true
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Magic comments should be in the following order: typed, encoding, warn_indent, frozen_string_literal.
      # typed: true
      ^^^^^^^^^^^^^ Magic comments should be in the following order: typed, encoding, warn_indent, frozen_string_literal.
      class Foo; end
    RUBY
  end

  it('makes offense when all magic comments are not correctly ordered') do
    expect_offense(<<~RUBY)
      # encoding: utf-8
      ^^^^^^^^^^^^^^^^^ Magic comments should be in the following order: typed, encoding, warn_indent, frozen_string_literal.
      # frozen_string_literal: true
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Magic comments should be in the following order: typed, encoding, warn_indent, frozen_string_literal.
      # warn_indent: true
      ^^^^^^^^^^^^^^^^^^^ Magic comments should be in the following order: typed, encoding, warn_indent, frozen_string_literal.
      # typed: true
      ^^^^^^^^^^^^^ Magic comments should be in the following order: typed, encoding, warn_indent, frozen_string_literal.
      # coding: utf-8
      ^^^^^^^^^^^^^^^ Magic comments should be in the following order: typed, encoding, warn_indent, frozen_string_literal.
      class Foo; end
    RUBY
  end

  describe('autocorrect') do
    it('autocorrects two magic comments in the correct order') do
      source = <<~RUBY
        # frozen_string_literal: true
        # typed: true
        class Foo; end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          # typed: true
          # frozen_string_literal: true
          class Foo; end
        RUBY
    end

    it('autocorrects all magic comments in the correct order') do
      source = <<~RUBY
        # encoding: utf-8
        # frozen_string_literal: true
        # warn_indent: true
        # typed: true
        # coding: utf-8
        class Foo; end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          # typed: true
          # encoding: utf-8
          # coding: utf-8
          # warn_indent: true
          # frozen_string_literal: true
          class Foo; end
        RUBY
    end

    it('autocorrects all magic comments in the correct order even with random comments in the middle') do
      source = <<~RUBY
        # encoding: utf-8
        # foo
        # frozen_string_literal: true
        # bar: true
        # warn_indent: true
        # baz: "Hello"
        # typed: true
        # coding: utf-8
        # another foo
        class Foo; end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          # typed: true
          # foo
          # encoding: utf-8
          # bar: true
          # coding: utf-8
          # baz: "Hello"
          # warn_indent: true
          # frozen_string_literal: true
          # another foo
          class Foo; end
        RUBY
    end
  end
end
