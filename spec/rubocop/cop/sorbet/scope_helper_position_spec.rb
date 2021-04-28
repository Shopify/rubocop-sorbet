# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ScopeHelperPosition, :config) do
  subject(:cop) { described_class.new(config) }

  describe("offenses") do
    it("disallows using interface! after method definitions") do
      expect_offense(<<~RUBY)
        module Interface
          extend T::Sig
          extend T::Helpers

          sig { abstract.void }
          def foo; end

          interface!
          ^^^^^^^^^^ Cannot invoke interface! after method definitions

          sig { abstract.void }
          def bar; end
        end
      RUBY
    end

    it("disallows abstract! after method definitions") do
      expect_offense(<<~RUBY)
        module Interface
          extend T::Sig
          extend T::Helpers

          sig { abstract.void }
          def foo; end

          abstract!
          ^^^^^^^^^ Cannot invoke abstract! after method definitions

          sig { abstract.void }
          def bar; end
        end
      RUBY
    end

    it("disallows final! after method definitions") do
      expect_offense(<<~RUBY)
        module Interface
          extend T::Sig
          extend T::Helpers

          sig { abstract.void }
          def foo; end

          final!
          ^^^^^^ Cannot invoke final! after method definitions

          sig { abstract.void }
          def bar; end
        end
      RUBY
    end

    it("autocorrects moving the invocation to the right spot") do
      source = <<~RUBY
        module Interface
          extend T::Sig
          extend T::Helpers

          sig { abstract.void }
          def foo; end

          final!

          sig { abstract.void }
          def bar; end
        end
      RUBY

      corrected_source = <<~CORRECTED
        module Interface
          extend T::Sig
          extend T::Helpers

          final!

          sig { abstract.void }
          def foo; end

          sig { abstract.void }
          def bar; end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("autocorrects when there are no spaces after method definition") do
      source = <<~RUBY
        module Interface
          extend T::Sig
          extend T::Helpers

          sig { abstract.void }
          def foo; end
          final!

          sig { abstract.void }
          def bar; end
        end
      RUBY

      corrected_source = <<~CORRECTED
        module Interface
          extend T::Sig
          extend T::Helpers

          final!

          sig { abstract.void }
          def foo; end

          sig { abstract.void }
          def bar; end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("autocorrects when there are no spaces before method definition") do
      source = <<~RUBY
        module Interface
          extend T::Sig
          extend T::Helpers

          sig { abstract.void }
          def foo; end

          final!
          sig { abstract.void }
          def bar; end
        end
      RUBY

      corrected_source = <<~CORRECTED
        module Interface
          extend T::Sig
          extend T::Helpers

          final!

          sig { abstract.void }
          def foo; end

          sig { abstract.void }
          def bar; end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("autocorrects when there are no signatures") do
      source = <<~RUBY
        class Final
          extend T::Sig
          extend T::Helpers

          def foo; end

          final!

          def bar; end
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Final
          extend T::Sig
          extend T::Helpers

          final!

          def foo; end

          def bar; end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end
  end
end
