# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidSigWithRuntime, :config) do
  def message
    RuboCop::Cop::Sorbet::ForbidSigWithRuntime::MSG
  end

  describe("offenses") do
    it("allows using T::Sig::WithoutRuntime.sig") do
      expect_no_offenses(<<~RUBY)
        T::Sig::WithoutRuntime.sig { void }
        def foo; end
      RUBY
    end

    it("allows using sig") do
      expect_no_offenses(<<~RUBY)
        sig { void }
        def foo; end
      RUBY
    end

    it("disallows using T::Sig.sig { ... }") do
      expect_offense(<<~RUBY)
        T::Sig.sig { void }
        ^^^^^^^^^^^^^^^^^^^ #{message}
        def foo; end
      RUBY
    end

    it("disallows using T::Sig.sig do ... end") do
      expect_offense(<<~RUBY)
        T::Sig.sig do
        ^^^^^^^^^^^^^ #{message}
          void
        end
        def self.foo(x); end
      RUBY
    end
  end
end
