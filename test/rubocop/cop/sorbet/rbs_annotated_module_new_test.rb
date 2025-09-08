# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class RBSAnnotatedModuleNewTest < ::Minitest::Test
        def setup
          config = RuboCop::Config.new(
            "Sorbet/RBSAnnotatedModuleNew" => {
              "Annotations" => ["abstract", "interface", "sealed", "final", "requires_ancestor"],
            },
          )
          @cop = RBSAnnotatedModuleNew.new(config, {})
        end

        def test_registers_offense_for_abstract_with_simple_class_new
          assert_offense(<<~RUBY)
            # @abstract
            Foo = Class.new
            ^^^^^^^^^^^^^^^ Sorbet RBS annotations (@abstract) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @abstract
            class Foo
            end
          RUBY
        end

        def test_registers_offense_for_interface_with_module_new
          assert_offense(<<~RUBY)
            # @interface
            Bar = Module.new
            ^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@interface) do not work with dynamic `module.new` instantiation. Use regular module syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @interface
            module Bar
            end
          RUBY
        end

        def test_registers_offense_for_sealed_with_class_new
          assert_offense(<<~RUBY)
            # @sealed
            Baz = Class.new
            ^^^^^^^^^^^^^^^ Sorbet RBS annotations (@sealed) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @sealed
            class Baz
            end
          RUBY
        end

        def test_registers_offense_for_requires_ancestor_with_class_new
          assert_offense(<<~RUBY)
            # @requires_ancestor: SomeModule
            Qux = Class.new
            ^^^^^^^^^^^^^^^ Sorbet RBS annotations (@requires_ancestor) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @requires_ancestor: SomeModule
            class Qux
            end
          RUBY
        end

        def test_registers_offense_for_final_with_class_new
          assert_offense(<<~RUBY)
            # @final
            FinalClass = Class.new
            ^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@final) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @final
            class FinalClass
            end
          RUBY
        end

        def test_registers_offense_for_final_with_module_new
          assert_offense(<<~RUBY)
            # @final
            FinalModule = Module.new
            ^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@final) do not work with dynamic `module.new` instantiation. Use regular module syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @final
            module FinalModule
            end
          RUBY
        end

        def test_registers_offense_for_abstract_with_class_new_with_superclass
          assert_offense(<<~RUBY)
            # @abstract
            Bar = Class.new(Superclass)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@abstract) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @abstract
            class Bar < Superclass
            end
          RUBY
        end

        def test_registers_offense_for_abstract_with_class_new_with_block
          assert_offense(<<~RUBY)
            # @abstract
            Baz = Class.new do
            ^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@abstract) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
              def method
                "hello"
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            # @abstract
            class Baz
              def method
                "hello"
              end
            end
          RUBY
        end

        def test_registers_offense_for_interface_with_module_new_with_block
          assert_offense(<<~RUBY)
            # @interface
            MyModule = Module.new do
            ^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@interface) do not work with dynamic `module.new` instantiation. Use regular module syntax instead.
              def method
                "hello"
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            # @interface
            module MyModule
              def method
                "hello"
              end
            end
          RUBY
        end

        def test_registers_offense_for_abstract_with_class_new_with_superclass_and_block
          assert_offense(<<~RUBY)
            # @abstract
            Qux = Class.new(BaseClass) do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@abstract) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
              def method
                super + " world"
              end

              def another_method
                42
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            # @abstract
            class Qux < BaseClass
              def method
                super + " world"
              end

              def another_method
                42
              end
            end
          RUBY
        end

        def test_does_not_register_offense_for_class_new_without_annotation
          assert_no_offenses(<<~RUBY)
            # Some other comment
            Foo = Class.new
          RUBY
        end

        def test_does_not_register_offense_for_module_new_without_annotation
          assert_no_offenses(<<~RUBY)
            # Some other comment
            Foo = Module.new
          RUBY
        end

        def test_does_not_register_offense_for_regular_class_with_annotation
          assert_no_offenses(<<~RUBY)
            # @abstract
            class Foo
            end
          RUBY
        end

        def test_does_not_register_offense_for_regular_module_with_annotation
          assert_no_offenses(<<~RUBY)
            # @interface
            module Bar
            end
          RUBY
        end

        def test_does_not_register_offense_for_class_new_with_non_sorbet_comment
          assert_no_offenses(<<~RUBY)
            # @deprecated
            Bar = Class.new(Superclass)
          RUBY
        end

        def test_does_not_register_offense_for_annotation_comment_not_directly_above
          assert_no_offenses(<<~RUBY)
            # @abstract

            Foo = Class.new
          RUBY
        end

        def test_handles_namespaced_constants_with_class
          assert_offense(<<~RUBY)
            module MyModule
              # @abstract
              MyClass = Class.new
              ^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@abstract) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
            end
          RUBY

          assert_correction(<<~RUBY)
            module MyModule
              # @abstract
              class MyClass
              end
            end
          RUBY
        end

        def test_handles_namespaced_constants_with_module
          assert_offense(<<~RUBY)
            module OuterModule
              # @interface
              InnerModule = Module.new
              ^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@interface) do not work with dynamic `module.new` instantiation. Use regular module syntax instead.
            end
          RUBY

          assert_correction(<<~RUBY)
            module OuterModule
              # @interface
              module InnerModule
              end
            end
          RUBY
        end

        def test_handles_fully_qualified_class_constant
          assert_offense(<<~RUBY)
            # @abstract
            Foo = ::Class.new
            ^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@abstract) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @abstract
            class Foo
            end
          RUBY
        end

        def test_handles_fully_qualified_module_constant
          assert_offense(<<~RUBY)
            # @interface
            Bar = ::Module.new
            ^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@interface) do not work with dynamic `module.new` instantiation. Use regular module syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @interface
            module Bar
            end
          RUBY
        end

        def test_handles_explicit_namespace_constant_assignment
          assert_offense(<<~RUBY)
            # @abstract
            Foo::Bar = Class.new
            ^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@abstract) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @abstract
            class Foo::Bar
            end
          RUBY
        end

        def test_handles_explicit_namespace_module_assignment
          assert_offense(<<~RUBY)
            # @sealed
            Some::Deep::Module = Module.new
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@sealed) do not work with dynamic `module.new` instantiation. Use regular module syntax instead.
          RUBY

          assert_correction(<<~RUBY)
            # @sealed
            module Some::Deep::Module
            end
          RUBY
        end

        def test_preserves_block_body_with_multiple_methods
          assert_offense(<<~RUBY)
            # @abstract
            MyClass = Class.new do
            ^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@abstract) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
              attr_reader :value

              def initialize(value)
                @value = value
              end

              sig { returns(String) }
              def to_s
                value.to_s
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            # @abstract
            class MyClass
              attr_reader :value

              def initialize(value)
                @value = value
              end

              sig { returns(String) }
              def to_s
                value.to_s
              end
            end
          RUBY
        end

        def test_handles_multiple_annotations
          assert_offense(<<~RUBY)
            # @abstract
            # @sealed
            Foo = Class.new
            ^^^^^^^^^^^^^^^ Sorbet RBS annotations (@sealed) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
          RUBY
        end

        def test_custom_annotations_configuration
          config = RuboCop::Config.new(
            "Sorbet/RBSAnnotatedModuleNew" => {
              "Annotations" => ["custom_annotation"],
            },
          )
          @cop = RBSAnnotatedModuleNew.new(config, {})

          # Should detect custom annotation
          assert_offense(<<~RUBY)
            # @custom_annotation
            Foo = Class.new
            ^^^^^^^^^^^^^^^ Sorbet RBS annotations (@custom_annotation) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
          RUBY
        end

        def test_ignores_annotations_not_in_configuration
          config = RuboCop::Config.new(
            "Sorbet/RBSAnnotatedModuleNew" => {
              "Annotations" => ["abstract"],
            },
          )
          @cop = RBSAnnotatedModuleNew.new(config, {})

          # Should not detect @interface since it's not in the configured list
          assert_no_offenses(<<~RUBY)
            # @interface
            Foo = Class.new
          RUBY
        end

        def test_ignores_non_annotation_comments_starting_with_at
          assert_no_offenses(<<~RUBY)
            # @param name [String] the name
            Foo = Class.new
          RUBY

          assert_no_offenses(<<~RUBY)
            # @return [String]
            Bar = Module.new
          RUBY

          assert_no_offenses(<<~RUBY)
            # @note This is a note
            Baz = Class.new
          RUBY
        end

        def test_does_not_register_offense_for_non_constant_assignment
          # Local variable assignment
          assert_no_offenses(<<~RUBY)
            # @abstract
            foo = Class.new
          RUBY

          # Instance variable assignment
          assert_no_offenses(<<~RUBY)
            # @interface
            @bar = Module.new
          RUBY

          # Class variable assignment
          assert_no_offenses(<<~RUBY)
            # @sealed
            @@baz = Class.new
          RUBY
        end

        def test_does_not_register_offense_for_method_call_assignment
          assert_no_offenses(<<~RUBY)
            # @abstract
            self.foo = Class.new
          RUBY

          assert_no_offenses(<<~RUBY)
            # @interface
            foo[0] = Module.new
          RUBY
        end

        def test_handles_module_new_with_argument
          # Module.new doesn't support superclass like Class.new does,
          # but it can be passed a block
          assert_offense(<<~RUBY)
            # @interface
            MyInterface = Module.new do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@interface) do not work with dynamic `module.new` instantiation. Use regular module syntax instead.
              def method
                :result
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            # @interface
            module MyInterface
              def method
                :result
              end
            end
          RUBY
        end

        def test_handles_deeply_nested_blocks
          assert_offense(<<~RUBY)
            module OuterModule
              module InnerModule
                # @abstract
                DeeplyNested = Class.new do
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet RBS annotations (@abstract) do not work with dynamic `class.new` instantiation. Use regular class syntax instead.
                  attr_reader :value

                  def initialize(value)
                    @value = value
                  end
                end
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            module OuterModule
              module InnerModule
                # @abstract
                class DeeplyNested
                  attr_reader :value

                  def initialize(value)
                    @value = value
                  end
                end
              end
            end
          RUBY
        end
      end
    end
  end
end
