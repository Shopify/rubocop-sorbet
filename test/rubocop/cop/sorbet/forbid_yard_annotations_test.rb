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
        end
      end
    end
  end
end
