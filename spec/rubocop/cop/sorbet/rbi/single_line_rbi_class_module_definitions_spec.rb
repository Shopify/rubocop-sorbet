# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(RuboCop::Cop::Sorbet::SingleLineRbiClassModuleDefinitions, :config) do
  subject(:cop) { described_class.new(config) }

  describe('offences') do
    it 'registers an offense when an empty module definition is split across multiple lines' do
      expect_offense(<<~RBI)
        module MyModule
        ^^^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.
        end

        module SecondModule
        ^^^^^^^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.
        end
      RBI
    end

    it 'registers an offence when an empty class definition is split across multiple lines' do
      expect_offense(<<~RBI)
        class MyClass
        ^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.
        end

        class AnotherClass < SomeParentClass
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Empty class/module definitions in RBI files should be on a single line.
        end
      RBI
    end
  end

  describe('no offences') do
    it 'does not register an offense when empty module definition is done on a single line' do
      expect_no_offenses(<<~RBI)
        module MyModule; end

        module AnotherModule; end
      RBI
    end

    it 'does not register an offense when empty class definition is done on a single line' do
      expect_no_offenses(<<~RBI)
        class MyClass; end

        class AnotherClass < SomeParentClass; end
      RBI
    end

    it 'does not register an offence when a module is not empty' do
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

  describe('autocorrect') do
    it 'autocorrects multi-line module definitions to a single line' do
      source = <<~RBI
        module MyModule
        end

        module AnotherModule


        end
      RBI
      expect(autocorrect_source(source))
        .to(eq(<<~RBI))
          module MyModule; end

          module AnotherModule; end
        RBI
    end

    it 'autocorrects multi-line class definitions to a single line' do
      source = <<~RBI
        class MyClass




        end

        class AnotherClass < SomeClass
        end
      RBI
      expect(autocorrect_source(source))
        .to(eq(<<~RBI))
          class MyClass; end

          class AnotherClass < SomeClass; end
        RBI
    end

    it 'autocorrects multi-line definitions and ignores non-empty modules' do
      source = <<~RBI
        module MyModule
          def hello_world
          end
        end

        module ModuleWithWhitespace


        end
      RBI
      expect(autocorrect_source(source))
        .to(eq(<<~RBI))
          module MyModule
            def hello_world
            end
          end

          module ModuleWithWhitespace; end
        RBI
    end
  end
end
