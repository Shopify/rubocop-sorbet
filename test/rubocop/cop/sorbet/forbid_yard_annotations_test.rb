# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidYardAnnotationsTest < ::Minitest::Test
        MSG = "Sorbet/ForbidYardAnnotations: Avoid using YARD method annotations. Use RBS comment syntax instead."

        def setup
          @cop = ForbidYardAnnotations.new
        end

        def test_does_not_register_offense_for_regular_comments
          assert_no_offenses(<<~RUBY)
            class Example
              # This is a regular comment
              # TODO: This is a regular todo (not YARD)
              # NOTE: This is a regular note (not YARD)
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY
        end

        def test_registers_offense_for_param_annotation
          assert_offense(<<~RUBY)
            class Example
              # @param name [String] the name
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: (String) -> void
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY
        end

        def test_registers_offense_for_return_annotation
          assert_offense(<<~RUBY)
            class Example
              # @return [String] the greeting
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: () -> String
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY
        end

        def test_registers_offense_for_multiple_param_annotations_with_wrapped_lines
          assert_offense(<<~RUBY)
            class Example
              # @param first_name [String] the first name
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              #   of the person
              # @param last_name [String] the last name
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              #    of the person
              # @return
              ^^^^^^^^^ #{MSG}
              #   [String] the full name for the person
              def full_name(first_name, last_name)
                "\#{first_name} \#{last_name}"
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: (String, String) -> String
              def full_name(first_name, last_name)
                "\#{first_name} \#{last_name}"
              end
            end
          RUBY
        end

        def test_registers_offense_for_yield_annotations
          assert_offense(<<~RUBY)
            class Example
              # @yield [block_arg, two_arg] yields the processed value
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @yieldreturn [String] the processed result
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def process_value(value)
                yield(value, 2)
              end

              # @yield [block_arg] yields the processed value
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def just_yield
                yield(1)
              end

              # @yieldreturn [String] the processed result
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def just_yieldreturn
                yield(1, 2)
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: () { (untyped, untyped) -> String } -> void
              def process_value(value)
                yield(value, 2)
              end

              #: () { (untyped) -> void } -> void
              def just_yield
                yield(1)
              end

              #: () { () -> String } -> void
              def just_yieldreturn
                yield(1, 2)
              end
            end
          RUBY
        end

        def test_registers_offense_for_yieldparam_annotations
          assert_offense(<<~RUBY)
            class Example
              # @yieldparam block_arg [String] the value to process
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @yieldparam two_arg [Integer] the value to process
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @yieldreturn [String] the processed result
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def process_value(value)
                yield(value, 2)
              end

              # @yieldparam block_arg [String] the value to process
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def just_yieldparam
                yield(1)
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: () { (String, Integer) -> String } -> void
              def process_value(value)
                yield(value, 2)
              end

              #: () { (String) -> void } -> void
              def just_yieldparam
                yield(1)
              end
            end
          RUBY
        end

        def test_registers_offense_for_option_annotation
          assert_offense(<<~RUBY)
            class Example
              # @option opts [String] :name The name
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @option opts [Integer] :age The age
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def process_options(opts = {})
                # implementation
              end

              # @param opts [Hash] The options to pass
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @option opts [String] :name The name
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @option opts [Integer] :age The age
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def with_param_annotation_too(opts = {})
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: ({ name: String, age: Integer }) -> void
              def process_options(opts = {})
                # implementation
              end

              #: ({ name: String, age: Integer }) -> void
              def with_param_annotation_too(opts = {})
              end
            end
          RUBY
        end

        def test_registers_offense_for_mixed_yard_and_regular_comments
          assert_offense(<<~RUBY)
            class Example
              # This is a regular comment
              # @param name [String] the name
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # Another regular comment
              # @return [String] the greeting
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # Final comment
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              # This is a regular comment
              # Another regular comment
              # Final comment
              #: (String) -> String
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY
        end

        def test_does_not_register_offense_for_yard_like_tag_inside_comment_line
          assert_no_offenses(<<~RUBY)
            class Example
              # This is a comment with a tag @param but not a YARD annotation
              # This is a comment with a tag @return but not a YARD annotation
              # This is a comment with a tag @option but not a YARD annotation
              # This is a comment with a tag @overload but not a YARD annotation
              # This is a comment with a tag @yield but not a YARD annotation
              # This is a comment with a tag @yieldparam but not a YARD annotation
              # This is a comment with a tag @yieldreturn but not a YARD annotation
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY
        end

        def test_registers_offense_for_yard_annotation_with_extra_spaces
          assert_offense(<<~RUBY)
            class Example
              #   @param name [String] the name with extra spaces
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              #    @return [String] the greeting with extra spaces
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: (String) -> String
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY
        end

        def test_registers_offense_for_yard_annotation_but_skips_wrapped_lines
          assert_offense(<<~RUBY)
            class Example
              # @param name [String] the name with extra spaces
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              #   @return [String] the greeting with extra spaces
              #   No error on return because it's wrapped and part of the @param
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: (String) -> void
              def greet(name)
                "Hello \#{name}"
              end
            end
          RUBY
        end

        def test_converting_common_types
          assert_offense(<<~RUBY)
            class Example
              # @param a [String] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [Integer] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [Float] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param d [Numeric] the fourth parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param e [Symbol] the fifth parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def basics(a,b,c,d,e); end

              # @param a [:monkey] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [42] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [3.14] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param d ["banana"] the fourth parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def basic_literals(a, b, c, d); end

              # @param a [Boolean] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [TrueClass] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [true] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param d [FalseClass] the fourth parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param e [false] the fifth parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def booleans(a,b,c,d,e); end

              # @param a [NilClass] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [nil] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [void] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def nothings(a, b, c); end

              # @param a [Array] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [Hash] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [Set] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def flexible_containers(a, b, c); end

              # @param a [Module] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [Class] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [Object] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def inheritence_basics(a, b, c); end

              # @param a [self] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [#duck_type] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def disallows(a, b); end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: (String, Integer, Float, Numeric, Symbol) -> void
              def basics(a,b,c,d,e); end

              #: (Symbol, Integer, Float, String) -> void
              def basic_literals(a, b, c, d); end

              #: (bool, TrueClass, TrueClass, FalseClass, FalseClass) -> void
              def booleans(a,b,c,d,e); end

              #: (NilClass, NilClass, void) -> void
              def nothings(a, b, c); end

              #: (Array, Hash, Set) -> void
              def flexible_containers(a, b, c); end

              #: (Module, Class, Object) -> void
              def inheritence_basics(a, b, c); end

              #: (untyped, untyped) -> void
              def disallows(a, b); end
            end
          RUBY
        end

        def test_handles_union_types
          assert_offense(<<~RUBY)
            class Example
              # @param a [String, Integer] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [Symbol, nil] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @yieldparam block_arg [String, Integer] the value to process
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def union_types(a, b); end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: (String | Integer, Symbol | NilClass) { (String | Integer) -> void } -> void
              def union_types(a, b); end
            end
          RUBY
        end

        def test_handles_type_specification_for_container_types
          assert_offense(<<~RUBY)
            class Example
              # @param a [Array<String>] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [Array<String, Symbol>] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [<String>] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param d [<String, Integer>] the fourth parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def array_examples(a,b,c,d); end

              # @param a [Hash<String, Integer>] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [Hash{Symbol=>Boolean}] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [Hash{Symbol, String => String, Integer}] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param d [{Symbol, String=>String, Boolean}] the fourth parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def hash_examples(a,b,c,d); end

              # @param a [Set<Numeric>] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [Set<Symbol, String>] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [List<String>] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [List<Integer, Float>] the fourth parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def custom_container_examples(a,b,c,d); end

              # @param a [Array(String)] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param b [Array(String, Integer)] the second parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param c [(String)] the third parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # @param d [(String, Integer)] the fourth parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def tuple_examples(a,b,c,d); end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: (Array[String], Array[String | Symbol], Array[String], Array[String | Integer]) -> void
              def array_examples(a,b,c,d); end

              #: (Hash[String, Integer], Hash[Symbol, bool], Hash[Symbol | String, String | Integer], Hash[Symbol | String, String | bool]) -> void
              def hash_examples(a,b,c,d); end

              #: (Set[Numeric], Set[Symbol | String], List[String], List[Integer | Float]) -> void
              def custom_container_examples(a,b,c,d); end

              #: ([String], [String, Integer], [String], [String, Integer]) -> void
              def tuple_examples(a,b,c,d); end
            end
          RUBY
        end

        def test_handles_nested_container_type_specifications
          assert_offense(<<~RUBY)
            class Example
              # @param a [Array<{Symbol,String=>(Set<Integer>, (String,String), <{Symbol=>Boolean}>)}>] the first parameter
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def nested_container_example(a); end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Example
              #: (Array[Hash[Symbol | String, [Set[Integer], [String, String], Array[Hash[Symbol, bool]]]]]) -> void
              def nested_container_example(a); end
            end
          RUBY
        end

        def test_registers_offense_for_overload_annotation
          assert_offense(<<~RUBY)
            class Example
              # @overload greet(name)
              ^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              #   @param name [String]
              #   @return [String]
              # @overload greet(first, last)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              #   @param first [String]
              #   @param last [String]
              #   @return [String]
              def greet(*args)
                # implementation
              end
            end
          RUBY
        end
      end
    end
  end
end
