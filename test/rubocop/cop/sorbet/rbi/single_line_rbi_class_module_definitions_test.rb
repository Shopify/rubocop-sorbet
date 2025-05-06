# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Rbi
        class SingleLineRbiClassModuleDefinitionsTest < ::Minitest::Test
          MSG = "Sorbet/SingleLineRbiClassModuleDefinitions: Empty class/module definitions in RBI files should be on a single line."

          def setup
            @cop = SingleLineRbiClassModuleDefinitions.new
          end

          def test_registers_offense_when_empty_module_definition_is_split_across_multiple_lines
            assert_offense(<<~RUBY)
              module MyModule
              ^^^^^^^^^^^^^^^ #{MSG}
              end

              module SecondModule
              ^^^^^^^^^^^^^^^^^^^ #{MSG}


              end

              module ThirdModule
                def some_method
                end
              end
            RUBY

            assert_correction(<<~RUBY)
              module MyModule; end

              module SecondModule; end

              module ThirdModule
                def some_method
                end
              end
            RUBY
          end

          def test_registers_offense_when_empty_class_definition_is_split_across_multiple_lines
            assert_offense(<<~RUBY)
              class MyClass
              ^^^^^^^^^^^^^ #{MSG}
              end

              class AnotherClass < SomeParentClass
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY

            assert_correction(<<~RUBY)
              class MyClass; end

              class AnotherClass < SomeParentClass; end
            RUBY
          end

          def test_does_not_register_offense_when_empty_module_definition_is_on_single_line
            assert_no_offenses(<<~RUBY)
              module MyModule; end

              module AnotherModule; end
            RUBY
          end

          def test_does_not_register_offense_when_empty_class_definition_is_on_single_line
            assert_no_offenses(<<~RUBY)
              class MyClass; end

              class AnotherClass < SomeParentClass; end
            RUBY
          end

          def test_does_not_register_offense_when_module_is_not_empty
            assert_no_offenses(<<~RUBY)
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
    end
  end
end
