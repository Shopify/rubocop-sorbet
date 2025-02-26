# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidSigWithoutRuntime, :config) do
  def message
    RuboCop::Cop::Sorbet::ForbidSigWithoutRuntime::MSG
  end

  describe("offenses") do
    it("allows using sig") do
      expect_no_offenses(<<~RUBY)
        sig { void }
        def foo; end
      RUBY
    end

    it("disallows using T::Sig::WithoutRuntime.sig { ... }") do
      expect_offense(<<~RUBY)
        T::Sig::WithoutRuntime.sig { void }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
        def foo; end
      RUBY

      expect_correction(<<~RUBY)
        sig { void }
        def foo; end
      RUBY
    end

    it("disallows using T::Sig::WithoutRuntime.sig do ... end") do
      expect_offense(<<~RUBY)
        T::Sig::WithoutRuntime.sig do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
          void
        end
        def self.foo(x); end
      RUBY

      expect_correction(<<~RUBY)
        sig do
          void
        end
        def self.foo(x); end
      RUBY
    end

    it("autocorrects with the correct parameters and block") do
      expect_offense(<<~RUBY)
        T::Sig::WithoutRuntime.sig(:final) do
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
          params(
            x: A,
            y: B,
          ).returns(C)
        end
        def self.foo(x, y); end
      RUBY

      expect_correction(<<~RUBY)
        sig(:final) do
          params(
            x: A,
            y: B,
          ).returns(C)
        end
        def self.foo(x, y); end
      RUBY
    end

    it("autocorrects with the correct parameters and block in a multiline sig") do
      expect_offense(<<~RUBY)
        T::
        ^^^ #{message}
          Sig::
            WithoutRuntime
              .sig(:final) do
          params(
            x: A,
            y: B,
          ).returns(C)
        end
        def self.foo(x, y); end
      RUBY

      expect_correction(<<~RUBY)
        sig(:final) do
          params(
            x: A,
            y: B,
          ).returns(C)
        end
        def self.foo(x, y); end
      RUBY
    end
  end
end
