# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ConstantsFromStrings, :config) do
  def message(method_name)
    "Don't use `#{method_name}`, it makes the code harder to understand, less editor-friendly, " \
      "and impossible to analyze. Replace `#{method_name}` with a case/when or a hash."
  end

  describe("offenses") do
    it("disallows constantize") do
      expect_offense(<<~RUBY)
        klass = "Foo".constantize
                      ^^^^^^^^^^^ #{message("constantize")}
      RUBY
    end

    it("disallows constantize with safe navigation") do
      expect_offense(<<~RUBY)
        klass = class_name&.constantize
                            ^^^^^^^^^^^ #{message("constantize")}
      RUBY
    end

    it("disallows safe_constantize") do
      expect_offense(<<~RUBY)
        klass = "Foo".safe_constantize
                      ^^^^^^^^^^^^^^^^ #{message("safe_constantize")}
      RUBY
    end

    it("disallows safe_constantize with safe navigation") do
      expect_offense(<<~RUBY)
        klass = class_name&.safe_constantize
                            ^^^^^^^^^^^^^^^^ #{message("safe_constantize")}
      RUBY
    end

    it("disallows const_get with receiver") do
      expect_offense(<<~RUBY)
        klass = Object.const_get("Foo")
                       ^^^^^^^^^ #{message("const_get")}
      RUBY
    end

    it("disallows const_get without receiver") do
      expect_offense(<<~RUBY)
        klass = const_get("Foo")
                ^^^^^^^^^ #{message("const_get")}
      RUBY
    end

    it("disallows constants with receiver") do
      expect_offense(<<~RUBY)
        klass = Object.constants.select { |c| c.name == "Foo" }
                       ^^^^^^^^^ #{message("constants")}
      RUBY
    end

    it("disallows constants without receiver") do
      expect_offense(<<~RUBY)
        klass = constants.select { |c| c.name == "Foo" }
                ^^^^^^^^^ #{message("constants")}
      RUBY
    end
  end
end
