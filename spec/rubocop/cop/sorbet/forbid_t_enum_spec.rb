# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidTEnum, :config) do
  describe("Offenses") do
    it "adds offense when inheriting T::Enum on a multiline class" do
      expect_offense(<<~RUBY)
        class Foo < T::Enum
        ^^^^^^^^^^^^^^^^^^^ Using `T::Enum` is deprecated in this codebase.
        end
      RUBY
    end

    it "adds offense when inheriting T::Enum on a singleline class" do
      expect_offense(<<~RUBY)
        class Foo < T::Enum; end
        ^^^^^^^^^^^^^^^^^^^^^^^^ Using `T::Enum` is deprecated in this codebase.
      RUBY
    end

    it "adds offense when inheriting ::T::Enum" do
      expect_offense(<<~RUBY)
        class Foo < ::T::Enum; end
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `T::Enum` is deprecated in this codebase.
      RUBY
    end

    it "adds offense for nested enums" do
      expect_offense(<<~RUBY)
        class Foo < T::Enum
        ^^^^^^^^^^^^^^^^^^^ Using `T::Enum` is deprecated in this codebase.
          class Bar < T::Enum
          ^^^^^^^^^^^^^^^^^^^ Using `T::Enum` is deprecated in this codebase.
          end
        end
      RUBY
    end
  end

  describe("No offenses") do
    it "does not add offense when not using T::Enum" do
      expect_no_offenses(<<~RUBY)
        class Foo
        end

        class Bar < Baz; end

        class Baz
          extend T::Enum
        end

        class T::Enum; end
      RUBY
    end
  end
end
