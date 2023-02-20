# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::EnforceSingleSigil, :config) do
  describe("no offenses") do
    it("makes no offense on empty files") do
      expect_no_offenses(<<~RUBY)
      RUBY
    end

    it("makes no offense with only one sigil") do
      expect_no_offenses(<<~RUBY)
        # typed: true
        class Foo; end
      RUBY
    end

    it("makes no offense with only one sigil and other comments") do
      expect_no_offenses(<<~RUBY)
        # typed: true
        # frozen_string_literal: true
        class Foo; end
      RUBY
    end

    it("makes no offense with only one sigil and other sigil in the middle of a comment") do
      expect_no_offenses(<<~RUBY)
        # typed: true
        #
        # Something something `# typed: true`
        class Foo; end
      RUBY
    end
  end

  describe("offenses") do
    it("makes offense when two sigils are present") do
      expect_offense(<<~RUBY)
        # typed: true
        # typed: false
        ^^^^^^^^^^^^^^ Files must only contain one sigil
        class Foo; end
      RUBY
    end

    it("makes offense on every extra sigil beyond the first one") do
      expect_offense(<<~RUBY)
        # typed: true
        # typed: false
        ^^^^^^^^^^^^^^ Files must only contain one sigil
        # typed: true
        ^^^^^^^^^^^^^ Files must only contain one sigil
        class Foo; end
      RUBY
    end

    it("makes offense on every extra sigil beyond the first one when there are other comments in between") do
      expect_offense(<<~RUBY)
        # typed: true
        # typed: false
        ^^^^^^^^^^^^^^ Files must only contain one sigil
        # frozen_string_literal: true
        # hello there
        # typed: true
        ^^^^^^^^^^^^^ Files must only contain one sigil
        class Foo; end
      RUBY
    end
  end

  describe("autocorrect") do
    it("autocorrects duplicate sigils by removing extras") do
      source = <<~RUBY
        # typed: true
        # typed: true
        # typed: true
        # typed: true
        # typed: true
        class Foo; end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          # typed: true
          class Foo; end
        RUBY
    end

    it("autocorrects duplicate sigils by selecting the first as the 'real' sigil") do
      source = <<~RUBY
        # typed: true
        # typed: false
        # typed: strict
        # frozen_string_literal: true
        # typed: strong
        # typed: ignore
        class Foo; end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          # typed: true
          # frozen_string_literal: true
          class Foo; end
        RUBY
    end
  end
end
