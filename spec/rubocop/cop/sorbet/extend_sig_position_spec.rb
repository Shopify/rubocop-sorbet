# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ExtendSigPosition, :config) do
  subject(:cop) { described_class.new(config) }

  describe("offenses") do
    it("enforces that extend T::Sig is the first line in a class/module") do
      expect_offense(<<~RUBY)
        class Abstract
          include Something
          extend T::Sig
          ^^^^^^^^^^^^^ extend T::Sig should be the first statement of a class/module
        end
      RUBY
    end
  end

  describe("valid uses") do
    it("respects usage of nested modules or classes") do
      expect_no_offenses(<<~RUBY)
        module Namespace
          extend T::Sig

          class First
            extend T::Sig
            include Something
          end

          class Second
            extend T::Sig
            include Something
          end
        end
      RUBY
    end
  end

  describe("autocorrect") do
    it("moves the extend to the first position inside class/module") do
      source = <<~RUBY
        class Abstract
          include Something
          extend T::Sig
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Abstract
          extend T::Sig
          include Something
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("handles empty lines before extend") do
      source = <<~RUBY
        class Abstract
          include Something

          extend T::Sig
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Abstract
          extend T::Sig
          include Something
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("handles empty lines after extend") do
      source = <<~RUBY
        class Abstract
          include Something

          extend T::Sig

          def foo; end
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Abstract
          extend T::Sig
          include Something

          def foo; end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("handles nested classes/modules") do
      source = <<~RUBY
        module Namespace
          include Something
          extend T::Sig

          class First
            include AnotherThing
            extend T::Sig
          end

          class Second
            include AnotherThing
            extend T::Sig
          end
        end
      RUBY

      corrected_source = <<~CORRECTED
        module Namespace
          extend T::Sig
          include Something

          class First
            extend T::Sig
            include AnotherThing
          end

          class Second
            extend T::Sig
            include AnotherThing
          end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end
  end
end
