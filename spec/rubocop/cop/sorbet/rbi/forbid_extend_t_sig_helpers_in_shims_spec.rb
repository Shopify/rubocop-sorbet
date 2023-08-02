# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidExtendTSigHelpersInShims, :config) do
  describe("offences") do
    it "adds an offence when a targeted class or module extends T::Sig or T::Helpers" do
      expect_offense(<<~RUBY)
        module MyModule
          extend T::Sig
          ^^^^^^^^^^^^^ Extending T::Sig or T::Helpers in a shim is unnecessary
          extend T::Helpers
          ^^^^^^^^^^^^^^^^^ Extending T::Sig or T::Helpers in a shim is unnecessary

          sig { returns(String) }
          def foo; end
        end
      RUBY

      expect_correction(<<~RUBY)
        module MyModule

          sig { returns(String) }
          def foo; end
        end
      RUBY
    end

    it "adds an offence when an extend T::Sig or extend T::Helpers call uses parenthesis syntax" do
      expect_offense(<<~RUBY)
        module MyModule
          extend(T::Sig)
          ^^^^^^^^^^^^^^ Extending T::Sig or T::Helpers in a shim is unnecessary
          extend(T::Helpers)
          ^^^^^^^^^^^^^^^^^^ Extending T::Sig or T::Helpers in a shim is unnecessary

          sig { returns(String) }
          def foo; end
        end
      RUBY

      expect_correction(<<~RUBY)
        module MyModule

          sig { returns(String) }
          def foo; end
        end
      RUBY
    end

    it "adds an offense when extend T::Sig or extend T::Helpers are extended in otherwise empty classes or modules" do
      expect_offense(<<~RUBY)
        module MyModule
          extend(T::Sig)
          ^^^^^^^^^^^^^^ Extending T::Sig or T::Helpers in a shim is unnecessary
        end

        class MyClass
          extend(T::Helpers)
          ^^^^^^^^^^^^^^^^^^ Extending T::Sig or T::Helpers in a shim is unnecessary
        end
      RUBY

      expect_correction(<<~RUBY)
        module MyModule
        end

        class MyClass
        end
      RUBY
    end
  end

  describe("no offences") do
    it "does not add an offence to uses of extend that are not T::Sig or T::Helpers" do
      expect_no_offenses(<<~RUBY)
        module MyModule
          extend ActiveSupport::Concern

          def foo; end
        end
      RUBY
    end
  end
end
