# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class RedundantTLetForLiteralTest < ::Minitest::Test
        MSG = "Sorbet/RedundantTLetForLiteral: Redundant `T.let` for %{type} literal. " \
          "Sorbet can infer this type automatically."

        def setup
          @cop = RedundantTLetForLiteral.new
        end

        # String literals

        def test_registers_offense_for_double_quoted_string
          assert_offense(<<~RUBY)
            GREETING = T.let("hello", String)
                       ^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "String")}
          RUBY

          assert_correction(<<~RUBY)
            GREETING = "hello"
          RUBY
        end

        def test_registers_offense_for_single_quoted_string
          assert_offense(<<~RUBY)
            GREETING = T.let('hello', String)
                       ^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "String")}
          RUBY

          assert_correction(<<~RUBY)
            GREETING = 'hello'
          RUBY
        end

        # Integer literals

        def test_registers_offense_for_positive_integer
          assert_offense(<<~RUBY)
            MAX_RETRIES = T.let(3, Integer)
                          ^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Integer")}
          RUBY

          assert_correction(<<~RUBY)
            MAX_RETRIES = 3
          RUBY
        end

        def test_registers_offense_for_negative_integer
          assert_offense(<<~RUBY)
            ERROR_CODE = T.let(-32601, Integer)
                         ^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Integer")}
          RUBY

          assert_correction(<<~RUBY)
            ERROR_CODE = -32601
          RUBY
        end

        # Float literals

        def test_registers_offense_for_float
          assert_offense(<<~RUBY)
            RATE = T.let(1.5, Float)
                   ^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Float")}
          RUBY

          assert_correction(<<~RUBY)
            RATE = 1.5
          RUBY
        end

        # Symbol literals

        def test_registers_offense_for_symbol
          assert_offense(<<~RUBY)
            STATUS = T.let(:active, Symbol)
                     ^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Symbol")}
          RUBY

          assert_correction(<<~RUBY)
            STATUS = :active
          RUBY
        end

        # Regexp literals

        def test_registers_offense_for_regexp_literal
          assert_offense(<<~RUBY)
            PATTERN = T.let(/foo/, Regexp)
                      ^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Regexp")}
          RUBY

          assert_correction(<<~RUBY)
            PATTERN = /foo/
          RUBY
        end

        def test_registers_offense_for_percent_r_regexp
          assert_offense(<<~RUBY)
            PATTERN = T.let(%r{foo/bar}, Regexp)
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Regexp")}
          RUBY

          assert_correction(<<~RUBY)
            PATTERN = %r{foo/bar}
          RUBY
        end

        # Type does not match

        def test_no_offense_for_nilable_type
          assert_no_offenses(<<~RUBY)
            value = T.let("hello", T.nilable(String))
          RUBY
        end

        def test_no_offense_when_class_does_not_match_literal
          assert_no_offenses(<<~RUBY)
            value = T.let(42, Float)
          RUBY
        end

        def test_no_offense_when_widening_to_superclass
          assert_no_offenses(<<~RUBY)
            FOO = T.let(42, Numeric)
          RUBY
        end

        # Non-simple literals

        def test_no_offense_for_array_literal
          assert_no_offenses(<<~RUBY)
            NAMES = T.let(["alice", "bob"], T::Array[String])
          RUBY
        end

        def test_no_offense_for_hash_literal
          assert_no_offenses(<<~RUBY)
            OPTIONS = T.let({ verbose: true }, T::Hash[Symbol, T::Boolean])
          RUBY
        end

        def test_no_offense_for_method_call
          assert_no_offenses(<<~RUBY)
            VALUE = T.let(ENV.fetch("FOO"), String)
          RUBY
        end

        def test_no_offense_for_regexp_new
          assert_no_offenses(<<~RUBY)
            PATTERN = T.let(Regexp.new("foo"), Regexp)
          RUBY
        end

        def test_registers_offense_for_heredoc_string
          assert_offense(<<~RUBY)
            MSG = T.let(<<~MESSAGE, String)
                  ^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "String")}
              hello world
            MESSAGE
          RUBY

          assert_correction(<<~RUBY)
            MSG = <<~MESSAGE
              hello world
            MESSAGE
          RUBY
        end

        def test_no_offense_for_complex_literal
          assert_no_offenses(<<~RUBY)
            VALUE = T.let(1 + 1i, Complex)
          RUBY
        end

        def test_no_offense_for_rational_literal
          assert_no_offenses(<<~RUBY)
            VALUE = T.let(0.3r, Rational)
          RUBY
        end

        def test_registers_offense_for_string_interpolation
          assert_offense(<<~'RUBY')
            FOO = T.let("#{42}", String)
                  ^^^^^^^^^^^^^^^^^^^^^^ Sorbet/RedundantTLetForLiteral: Redundant `T.let` for String literal. Sorbet can infer this type automatically.
          RUBY

          assert_correction(<<~'RUBY')
            FOO = "#{42}"
          RUBY
        end

        def test_no_offense_for_frozen_string
          assert_no_offenses(<<~RUBY)
            VALUE = T.let("hello".freeze, String)
          RUBY
        end

        def test_no_offense_for_frozen_symbol
          assert_no_offenses(<<~RUBY)
            STATUS = T.let(:active.freeze, Symbol)
          RUBY
        end

        def test_no_offense_for_frozen_heredoc
          assert_no_offenses(<<~RUBY)
            MSG = T.let(<<~MESSAGE.freeze, String)
              hello world
            MESSAGE
          RUBY
        end

        def test_registers_offense_for_frozen_regexp_literal
          assert_offense(<<~RUBY)
            PATTERN = T.let(/foo/.freeze, Regexp)
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Regexp")}
          RUBY

          assert_correction(<<~RUBY)
            PATTERN = /foo/.freeze
          RUBY
        end

        def test_no_offense_for_boolean_true
          assert_no_offenses(<<~RUBY)
            FLAG = T.let(true, T::Boolean)
          RUBY
        end

        def test_no_offense_for_boolean_false
          assert_no_offenses(<<~RUBY)
            FLAG = T.let(false, T::Boolean)
          RUBY
        end

        def test_no_offense_for_nil
          assert_no_offenses(<<~RUBY)
            VALUE = T.let(nil, T.nilable(String))
          RUBY
        end

        def test_no_offense_for_instance_variable_assignment
          assert_no_offenses(<<~RUBY)
            @max_retries = T.let(3, Integer)
          RUBY
        end

        def test_no_offense_for_instance_variable_with_string
          assert_no_offenses(<<~RUBY)
            @name = T.let("default", String)
          RUBY
        end

        # Namespaced constant types

        def test_no_offense_for_t_boolean
          assert_no_offenses(<<~RUBY)
            FLAG = T.let(true, T::Boolean)
          RUBY
        end

        def test_no_offense_for_custom_class
          assert_no_offenses(<<~RUBY)
            VALUE = T.let("hello", MyCustomString)
          RUBY
        end

        # Non-constant assignments

        def test_no_offense_for_local_variable
          assert_no_offenses(<<~RUBY)
            x = T.let(42, Integer)
          RUBY
        end

        def test_no_offense_for_class_variable
          assert_no_offenses(<<~RUBY)
            @@count = T.let(0, Integer)
          RUBY
        end

        def test_no_offense_for_global_variable
          assert_no_offenses(<<~RUBY)
            $verbose = T.let(true, T::Boolean)
          RUBY
        end

        # Edge cases

        def test_registers_offense_in_class_constant
          assert_offense(<<~RUBY)
            class Foo
              MAX = T.let(100, Integer)
                    ^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Integer")}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              MAX = 100
            end
          RUBY
        end

        def test_no_offense_when_receiver_is_not_t
          assert_no_offenses(<<~RUBY)
            value = SomeModule.let(42, Integer)
          RUBY
        end

        def test_handles_multiline_t_let_with_simple_literal
          assert_offense(<<~RUBY)
            MSG = T.let(
                  ^^^^^^ #{format(MSG, type: "String")}
              "out of order",
              String,
            )
          RUBY

          assert_correction(<<~RUBY)
            MSG = "out of order"
          RUBY
        end

        private

        def target_cop
          RedundantTLetForLiteral
        end
      end
    end
  end
end
