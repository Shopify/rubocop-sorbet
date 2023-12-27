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
      expect_offense(<<~RUBY)
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: type_parameters, params, void.
      RUBY
    end
  end

  describe("autocorrect") do
    it("autocorrects sigs in the correct order") do
      expect_offense <<~RUBY
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: type_parameters, params, void.
      RUBY

      expect_correction <<~RUBY
        sig { type_parameters(:U).params(x: T.type_parameter(:U)).void }
      RUBY
    end

    it("autocorrects sigs with generic types properly") do
      expect_offense <<~RUBY
        sig { void.type_parameters(:U).params(x: T.type_parameter(:U), y: T::Hash[String, Integer]) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: type_parameters, params, void.
      RUBY

      expect_correction <<~RUBY
        sig { type_parameters(:U).params(x: T.type_parameter(:U), y: T::Hash[String, Integer]).void }
      RUBY
    end

    it("autocorrects sigs even with many unknown methods") do
      expect_offense <<~RUBY
        sig { void.foo.type_parameters(:U).bar.params(x: T.type_parameter(:U), y: T::Hash[String, Integer]).baz }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: type_parameters, foo, params, bar, void, baz.
      RUBY

      expect_correction <<~RUBY
        sig { type_parameters(:U).foo.params(x: T.type_parameter(:U), y: T::Hash[String, Integer]).bar.void.baz }
      RUBY
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

    it("ignores unknown methods, while sorting the remainder of the chain") do
      expect_offense(<<~RUBY)
        sig { override.params(x: Integer).returns(Integer) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: returns, params, override.
      RUBY

      expect_correction(<<~RUBY)
        sig { returns(Integer).params(x: Integer).override }
      RUBY

      # Doesn't actually care about where params appears; only cares about relative ordering of returns and override.
      expect_offense(<<~RUBY)
        sig { override.returns(Integer).params(x: Integer) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: returns, override, params.
      RUBY

      expect_correction(<<~RUBY)
        sig { returns(Integer).override.params(x: Integer) }
      RUBY

      expect_offense(<<~RUBY)
        sig { params(x: Integer).override.returns(Integer) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: params, returns, override.
      RUBY

      expect_correction(<<~RUBY)
        sig { params(x: Integer).returns(Integer).override }
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
