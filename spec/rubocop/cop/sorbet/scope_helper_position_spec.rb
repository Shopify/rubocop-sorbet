# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ScopeHelperPosition, :config) do
  subject(:cop) { described_class.new(config) }

  describe("offenses") do
    it("disallows scope helpers after defining methods with reserved names") do
      expect_offense(<<~RUBY)
        class Foo
          extend T::Helpers

          def include; end
          abstract!
          ^^^^^^^^^ Cannot invoke abstract! after method definitions or invocations
        end
      RUBY
    end

    it("disallows using interface! after method definitions and invocations") do
      expect_offense(<<~RUBY)
        module Interface
          extend T::Sig
          extend T::Helpers

          sig { abstract.void }
          def foo; end

          interface!
          ^^^^^^^^^^ Cannot invoke interface! after method definitions or invocations

          sig { abstract.void }
          def bar; end
        end
      RUBY
    end

    it("disallows abstract! after method definitions and invocations") do
      expect_offense(<<~RUBY)
        module Interface
          extend T::Sig
          extend T::Helpers

          sig { abstract.void }
          def foo; end

          abstract!
          ^^^^^^^^^ Cannot invoke abstract! after method definitions or invocations

          sig { abstract.void }
          def bar; end
        end
      RUBY
    end

    it("disallows final! after method definitions and invocations") do
      expect_offense(<<~RUBY)
        class Final
          extend T::Sig
          extend T::Helpers

          validates :something, presence: true

          final!
          ^^^^^^ Cannot invoke final! after method definitions or invocations

          sig { abstract.void }
          def bar; end
        end
      RUBY
    end

    it("disallows sealed! after method definitions and invocations") do
      expect_offense(<<~RUBY)
        class Sealed
          extend T::Sig
          extend T::Helpers

          configure do
            something
          end

          sealed!
          ^^^^^^^ Cannot invoke sealed! after method definitions or invocations

          sig { abstract.void }
          def bar; end
        end
      RUBY
    end
  end

  describe("no offenses") do
    it("allows scope helpers after constants") do
      expect_no_offenses(<<~RUBY)
        class Abstract
          extend T::Helpers

          SOME_CONSTANT = "VALUE"

          abstract!
        end
      RUBY
    end

    it("allows scope helpers after requires_ancestor") do
      expect_no_offenses(<<~RUBY)
        module Interface
          extend(T::Sig)
          extend(T::Helpers)
          requires_ancestor(Kernel)

          interface!
        end
      RUBY
    end
  end

  describe("autocorrect") do
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

    it("autocorrects when there are method invocations") do
      source = <<~RUBY
        class Final
          extend T::Sig
          extend T::Helpers

          validates :something, presence: true

          final!
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Final
          extend T::Sig
          extend T::Helpers

          final!

          validates :something, presence: true
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("autocorrects when multiple scope helpers are used together") do
      source = <<~RUBY
        class Foo
          extend T::Helpers
        
          def foo; end
        
          interface!
          abstract!
          sealed!
          final!
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Foo
          extend T::Helpers

          final!

          sealed!

          abstract!

          interface!

          def foo; end

        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end
  end
end
