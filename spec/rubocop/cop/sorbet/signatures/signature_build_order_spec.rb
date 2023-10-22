# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::SignatureBuildOrder, :config) do
  describe("offenses") do
    it("allows the correct order") do
      expect_no_offenses(<<~RUBY)
        sig { abstract.params(x: Integer).returns(Integer) }

        sig { params(x: Integer).void }

        sig { abstract.void }

        sig { void.soft }

        sig { override.void.checked(false) }

        sig { overridable.void }
      RUBY
    end

    it("allows using multiline sigs") do
      expect_no_offenses(<<~RUBY)
        sig do
          abstract
            .params(x: Integer)
            .returns(Integer)
        end
      RUBY
    end

    it("doesn't break on incomplete signatures") do
      expect_no_offenses(<<~RUBY)
        sig {}
      RUBY

      expect_no_offenses(<<~RUBY)
        sig { params(a: Integer) }
      RUBY

      expect_no_offenses(<<~RUBY)
        sig { abstract }
      RUBY

      expect_no_offenses(<<~RUBY)
        sig { params(a: Integer).v }
      RUBY
    end

    it("enforces orders of builder calls") do
      message = "Sig builders must be invoked in the following order: type_parameters, params, void."
      expect_offense(<<~RUBY)
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    end
  end

  describe("autocorrect") do
    it("autocorrects sigs in the correct order") do
      source = <<~RUBY
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          sig { type_parameters(:U).params(x: T.type_parameter(:U)).void }
        RUBY
    end

    it("autocorrects sigs with generic types properly") do
      source = <<~RUBY
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U), y: T::Hash[String, Integer]) }
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          sig { type_parameters(:U).params(x: T.type_parameter(:U), y: T::Hash[String, Integer]).void }
        RUBY
    end
  end

  describe("without the unparser gem") do
    it("catches the errors and suggests using Unparser for the correction") do
      original_unparser = Unparser
      Object.send(:remove_const, :Unparser) # What does "constant" even mean?
      message =
        "Sig builders must be invoked in the following order: type_parameters, params, void. " \
          "For autocorrection, add the `unparser` gem to your project."

      expect_offense(<<~RUBY)
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      RUBY
    ensure
      Object.const_set(:Unparser, original_unparser)
    end
  end

  describe("config") do
    let :cop_config do
      {
        "Order" => [
          "returns",
          "override",
        ],
      }
    end

    it("ignores chains including unknown methods") do
      expect_no_offenses(<<~RUBY)
        sig { override.params(x: Integer).returns(Integer) } # params not in Order
      RUBY
    end

    it("allows customizing the order") do
      expect_offense(<<~RUBY)
        sig { override.returns(Integer) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: returns, override.
      RUBY

      expect_correction(<<~RUBY)
        sig { returns(Integer).override }
      RUBY
    end
  end
end
