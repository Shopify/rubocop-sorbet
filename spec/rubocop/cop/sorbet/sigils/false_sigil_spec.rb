# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::FalseSigil, :config) do
  describe("always require a ignore sigil") do
    it "makes offense if the strictness is not at least `false`" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # typed: ignore
        ^^^^^^^^^^^^^^^ Sorbet sigil should be at least `false` got `ignore`.
        class Foo; end
      RUBY
    end

    describe("autocorrect") do
      it("autocorrects by adding typed: false to file without sigil") do
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
