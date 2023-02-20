# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::SingleLineRbiClassModuleDefinitions, :config) do
  describe("offences") do
    it "registers an offense when an empty module definition is split across multiple lines" do
      expect_offense(<<~RBI)
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
      RBI

      expect_correction(<<~RBI)
        module MyModule; end

        module SecondModule; end

        module ThirdModule
          def some_method
          end
        end
      RBI
    end

    it "registers an offence when an empty class definition is split across multiple lines" do
      expect_offense(<<~RBI)
        class MyClass
        ^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.
        end

        class AnotherClass < SomeParentClass
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.
        end
      RBI

      expect_correction(<<~RBI)
        class MyClass; end

        class AnotherClass < SomeParentClass; end
      RBI
    end
  end

  describe("no offences") do
    it "does not register an offense when empty module definition is done on a single line" do
      expect_no_offenses(<<~RBI)
        module MyModule; end

        module AnotherModule; end
      RBI
    end

    it "does not register an offense when empty class definition is done on a single line" do
      expect_no_offenses(<<~RBI)
        class MyClass; end

        class AnotherClass < SomeParentClass; end
      RBI
    end

    it "does not register an offence when a module is not empty" do
      expect_no_offenses(<<~RBI)
        module MyModule
          def hello; end
        end

        module AnotherModule
          def world
          end
        end
      RBI
    end
  end
end
