# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::SingleLineRbiClassModuleDefinitions, :config) do
  describe("offences") do
    it "registers an offense when an empty module definition is split across multiple lines" do
      expect_offense(<<~RUBY)
        module MyModule
        ^^^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.
        end

        module SecondModule
        ^^^^^^^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.


        end

        module ThirdModule
          def some_method
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        module MyModule; end

        module SecondModule; end

        module ThirdModule
          def some_method
          end
        end
      RUBY
    end

    it "registers an offence when an empty class definition is split across multiple lines" do
      expect_offense(<<~RUBY)
        class MyClass
        ^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.
        end

        class AnotherClass < SomeParentClass
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.
        end
      RUBY

      expect_correction(<<~RUBY)
        class MyClass; end

        class AnotherClass < SomeParentClass; end
      RUBY
    end
  end

  describe("no offences") do
    it "does not register an offense when empty module definition is done on a single line" do
      expect_no_offenses(<<~RUBY)
        module MyModule; end

        module AnotherModule; end
      RUBY
    end

    it "does not register an offense when empty class definition is done on a single line" do
      expect_no_offenses(<<~RUBY)
        class MyClass; end

        class AnotherClass < SomeParentClass; end
      RUBY
    end

    it "does not register an offence when a module is not empty" do
      expect_no_offenses(<<~RUBY)
        module MyModule
          def hello; end
        end

        module AnotherModule
          def world
          end
        end
      RUBY
    end
  end
end
