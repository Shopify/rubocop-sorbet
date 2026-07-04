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

        # Array literals

        def test_registers_offense_for_unfrozen_array_matching_annotation
          assert_offense(<<~RUBY)
            NAMES = T.let(["alice", "bob"], T::Array[String])
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Array")}
          RUBY

          assert_correction(<<~RUBY)
            NAMES = ["alice", "bob"]
          RUBY
        end

        def test_registers_offense_for_frozen_array
          assert_offense(<<~RUBY)
            SHELLS = T.let([:bash, :zsh].freeze, T::Array[Symbol])
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Array")}
          RUBY

          assert_correction(<<~RUBY)
            SHELLS = [:bash, :zsh].freeze
          RUBY
        end

        def test_registers_offense_for_frozen_percent_word_array
          assert_offense(<<~RUBY)
            WORDS = T.let(%w[a b c].freeze, T::Array[String])
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Array")}
          RUBY

          assert_correction(<<~RUBY)
            WORDS = %w[a b c].freeze
          RUBY
        end

        # A frozen array infers as a tuple, a subtype of the annotated
        # T::Array, so it is redundant even when the elements are mixed and the
        # annotation is wider.
        def test_registers_offense_for_frozen_mixed_array
          assert_offense(<<~RUBY)
            VALUES = T.let([1, "a", nil].freeze, T::Array[T.nilable(T.any(Integer, String))])
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Array")}
          RUBY

          assert_correction(<<~RUBY)
            VALUES = [1, "a", nil].freeze
          RUBY
        end

        def test_registers_offense_for_frozen_nested_array
          assert_offense(<<~RUBY)
            PAIRS = T.let([["a"], ["b"]].freeze, T::Array[T::Array[String]])
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Array")}
          RUBY

          assert_correction(<<~RUBY)
            PAIRS = [["a"], ["b"]].freeze
          RUBY
        end

        # An unfrozen array whose annotation is wider than the inferred element
        # type must keep T.let, otherwise the type would be silently narrowed.
        def test_no_offense_for_unfrozen_array_with_wider_annotation
          assert_no_offenses(<<~RUBY)
            NAMES = T.let(["alice", "bob"], T::Array[T.nilable(String)])
          RUBY
        end

        # An unfrozen array with mixed element types is left alone: the inferred
        # element type is a union whose rendering is not verified here.
        def test_no_offense_for_unfrozen_mixed_array
          assert_no_offenses(<<~RUBY)
            VALUES = T.let([1, "a"], T::Array[T.any(Integer, String)])
          RUBY
        end

        # Empty arrays infer as T::Array[T.untyped], so the annotation is kept.
        def test_no_offense_for_empty_frozen_array
          assert_no_offenses(<<~RUBY)
            NAMES = T.let([].freeze, T::Array[String])
          RUBY
        end

        # Regexp and range elements degrade the array to T.untyped.
        def test_no_offense_for_frozen_regexp_array
          assert_no_offenses(<<~RUBY)
            PATTERNS = T.let([/a/, /b/].freeze, T::Array[Regexp])
          RUBY
        end

        def test_no_offense_for_frozen_range_array
          assert_no_offenses(<<~RUBY)
            RANGES = T.let([(1..2)].freeze, T::Array[T::Range[Integer]])
          RUBY
        end

        # Arrays whose elements are not literals (constants, method calls) are
        # not reflected into a tuple, so the annotation carries the type.
        def test_no_offense_for_array_of_constants
          assert_no_offenses(<<~RUBY)
            BROKERS = T.let([SEQUOIA, BENNIE].freeze, T::Array[String])
          RUBY
        end

        # Autocorrect safety illustrations
        #
        # These cases document why the cop is `SafeAutoCorrect: false`. The
        # correction is always type-sound at the definition (a frozen literal
        # array infers as a tuple, which is a subtype of the annotated
        # `T::Array`), but it changes the constant's inferred type from
        # `T::Array` to a tuple, and that can break typechecking at a consumer
        # the cop cannot see. The cop still registers and corrects these — the
        # tests capture that, so the hazard is explicit rather than silent.

        # After correction `CATEGORIES` infers as `[String, String]`. In a
        # `typed: strong` consumer, `flatten` over the tuple yields
        # `T.untyped`, which is an error there — so a green typecheck can turn
        # red even though the cop's edit looks innocuous.
        def test_autocorrect_narrows_frozen_array_to_tuple_unsafe_under_typed_strong
          assert_offense(<<~RUBY)
            # typed: strong
            class Report
              CATEGORIES = T.let(["a", "b"].freeze, T::Array[String])
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Array")}

              def all
                [CATEGORIES].flatten
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            # typed: strong
            class Report
              CATEGORIES = ["a", "b"].freeze

              def all
                [CATEGORIES].flatten
              end
            end
          RUBY
        end

        # After correction `BASIC` infers as `[Symbol, Symbol]`. A local seeded
        # from it and reassigned in a loop (`acc += ...`) then fails with
        # "Changing the type of a variable is not permitted in loops and
        # blocks", because the tuple type cannot widen to `T::Array[Symbol]`.
        def test_autocorrect_narrows_frozen_array_to_tuple_unsafe_for_loop_accumulator
          assert_offense(<<~RUBY)
            class Builder
              BASIC = T.let([:a, :b].freeze, T::Array[Symbol])
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Array")}

              def build
                acc = BASIC
                [1, 2].each { |n| acc += [n.to_s.to_sym] }
                acc
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Builder
              BASIC = [:a, :b].freeze

              def build
                acc = BASIC
                [1, 2].each { |n| acc += [n.to_s.to_sym] }
                acc
              end
            end
          RUBY
        end

        # Non-simple literals

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

        # In typed: strict, Sorbet requires T.let on constants assigned inside
        # a conditional or block, so those must not be flagged.
        def test_no_offense_for_constant_inside_conditional
          assert_no_offenses(<<~RUBY)
            if enabled?
              PATTERN = T.let(/foo/.freeze, Regexp)
              NAMES = T.let(["a", "b"].freeze, T::Array[String])
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

        # `T.let` may be called with a fully-qualified `::T`.
        def test_registers_offense_for_cbase_t_let
          assert_offense(<<~RUBY)
            MAX = ::T.let(3, Integer)
                  ^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Integer")}
          RUBY

          assert_correction(<<~RUBY)
            MAX = 3
          RUBY
        end

        # Both `::T.let` and a fully-qualified `::T::Array` annotation are handled.
        def test_registers_offense_for_cbase_t_and_t_array
          assert_offense(<<~RUBY)
            SHELLS = ::T.let([:bash, :zsh].freeze, ::T::Array[Symbol])
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, type: "Array")}
          RUBY

          assert_correction(<<~RUBY)
            SHELLS = [:bash, :zsh].freeze
          RUBY
        end

        # A multi-line annotation with a trailing comma still compares equal to
        # the inferred `T::Array[String]`.
        def test_registers_offense_for_unfrozen_array_multiline_annotation
          assert_offense(<<~RUBY)
            NAMES = T.let(
                    ^^^^^^ #{format(MSG, type: "Array")}
              ["alice", "bob"],
              T::Array[
                String,
              ],
            )
          RUBY

          assert_correction(<<~RUBY)
            NAMES = ["alice", "bob"]
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
