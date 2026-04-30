# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class RedundantTLetTest < ::Minitest::Test
        MSG = "Sorbet/RedundantTLet: Unnecessary T.let. The instance variable type is inferred from the signature."

        def setup
          @cop = RedundantTLet.new
        end

        def test_offense_on_redundant_types
          assert_offense(<<~RUBY)
            sig { params(a: Integer, b: String).void }
            def initialize(a, b)
              @a = T.let(a, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
              @b = T.let(b, String)
                   ^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Integer, b: String).void }
            def initialize(a, b)
              @a = T.let(b, String)
                   ^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Integer).void }
            def initialize(a:)
              @a = T.let(a, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Integer).void }
            def initialize(a = 5)
              @a = T.let(a, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: T.nilable(Integer)).void }
            def initialize(a)
              @a = T.let(a, T.nilable(Integer))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: T::Array[Integer]).void }
            def initialize(a)
              @a = T.let(a, T::Array[Integer])
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Foo[Bar], b: T.any(A, B), c: T.proc.void).void }
            def initialize(a, b, c)
              @a = T.let(a, Foo[Foo])
              @aa = T.let(a, Foo[Bar])
                    ^^^^^^^^^^^^^^^^^^ #{MSG}
              @b = T.let(b, T.any(B, A))
              @bb = T.let(b, T.any(A, B))
                    ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              @c = T.let(c, T.proc.returns(Integer))
              @cc = T.let(c, T.proc.void)
                    ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig do
              params(
                proc: T.proc.params(a: String).returns(T.nilable(String)),
              ).void
            end
            def initialize(proc)
              @proc = T.let(proc, T.proc.params(a: String).returns(T.nilable(String)))
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Integer, b: String, c: String, d: Integer).void }
            def initialize(a, b = "hello", c:, d: 1)
              @a = T.let(a, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
              @b = T.let(b, String)
                   ^^^^^^^^^^^^^^^^ #{MSG}
              @c = T.let(c, String)
                   ^^^^^^^^^^^^^^^^ #{MSG}
              @d = T.let(d, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            sig { params(a: Integer, b: String).void }
            def initialize(a, b)
              @a = a
              @b = b
            end

            sig { params(a: Integer, b: String).void }
            def initialize(a, b)
              @a = b
            end

            sig { params(a: Integer).void }
            def initialize(a:)
              @a = a
            end

            sig { params(a: Integer).void }
            def initialize(a = 5)
              @a = a
            end

            sig { params(a: T.nilable(Integer)).void }
            def initialize(a)
              @a = a
            end

            sig { params(a: T::Array[Integer]).void }
            def initialize(a)
              @a = a
            end

            sig { params(a: Foo[Bar], b: T.any(A, B), c: T.proc.void).void }
            def initialize(a, b, c)
              @a = T.let(a, Foo[Foo])
              @aa = a
              @b = T.let(b, T.any(B, A))
              @bb = b
              @c = T.let(c, T.proc.returns(Integer))
              @cc = c
            end

            sig do
              params(
                proc: T.proc.params(a: String).returns(T.nilable(String)),
              ).void
            end
            def initialize(proc)
              @proc = proc
            end

            sig { params(a: Integer, b: String, c: String, d: Integer).void }
            def initialize(a, b = "hello", c:, d: 1)
              @a = a
              @b = b
              @c = c
              @d = d
            end
          RUBY
        end

        def test_offense_on_args
          assert_offense(<<~RUBY)
            sig { params(args: Integer).void }
            def initialize(*args)
              @args = T.let(args, T::Array[Integer])
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            sig { params(args: Integer).void }
            def initialize(*args)
              @args = args
            end
          RUBY
        end

        def test_offense_on_kwargs
          assert_offense(<<~RUBY)
            sig { params(kwargs: String).void }
            def initialize(**kwargs)
              @kwargs = T.let(kwargs, T::Hash[Symbol, String])
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            sig { params(kwargs: String).void }
            def initialize(**kwargs)
              @kwargs = kwargs
            end
          RUBY
        end

        def test_no_offense_without_t_let
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            def initialize(a)
              @a = a
            end
          RUBY
        end

        def test_no_offense_without_sig
          assert_no_offenses(<<~RUBY)
            def initialize(a)
              @a = T.let(a, Integer)
            end
          RUBY
        end

        def test_no_offense_without_sig_params
          assert_no_offenses(<<~RUBY)
            sig { void }
            def initialize
              @a = T.let(0, Integer)
            end
          RUBY
        end

        def test_no_offense_without_initialize_method
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            def different_method(a)
              @a = T.let(a, Integer)
            end
          RUBY
        end

        def test_no_offense_on_necessary_t_lets
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer) }
            def initialize(a)
              @a = T.let(a, String)
            end

            sig { params(a: Integer).void }
            def initialize(a)
              @a = T.let(a, T.any(Integer, String))
            end

            sig { params(a: Integer).void }
            def initialize(a)
              @a = T.let(a.to_s, String)
            end

            sig { params(a: Integer).void }
            def initialize(a)
              number = a
              @answer = T.let(number, Integer)
            end

            sig { params(a: T.proc.params(x: Integer).returns(String)).void }
            def initialize(a)
              @a = T.let(a, T.proc.params(x: String).returns(String))
            end
          RUBY
        end

        def test_no_offense_inside_block
          assert_no_offenses(<<~RUBY)
            sig { params(items: T::Array[Integer]).void }
            def initialize(items)
              items.each do |item|
                @item = T.let(item, Integer)
              end
            end
          RUBY
        end

        def test_no_offense_inside_conditional
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            def initialize(a)
              if a > 0
                @a = T.let(a, Integer)
              end
            end
          RUBY
        end

        # Sorbet's initializer rewriter does not process ivar assignments
        # inside a rescue body, so T.let remains required there.
        def test_no_offense_with_rescue_in_body
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            def initialize(a)
              @a = T.let(a, Integer)
            rescue
              @a = T.let(0, Integer)
            end
          RUBY
        end

        # Multiline type annotations in the sig contain whitespace and trailing
        # commas that do not appear in the T.let argument; both sides are
        # normalized before comparison.
        def test_offense_on_multiline_type_in_sig
          assert_offense(<<~RUBY)
            sig do
              params(
                a: T.any(
                  Integer,
                  String,
                ),
              ).void
            end
            def initialize(a)
              @a = T.let(a, T.any(Integer, String))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            sig do
              params(
                a: T.any(
                  Integer,
                  String,
                ),
              ).void
            end
            def initialize(a)
              @a = a
            end
          RUBY
        end

        def test_offense_on_multiline_type_in_t_let
          assert_offense(<<~RUBY)
            sig { params(a: T.any(Integer, String)).void }
            def initialize(a)
              @a = T.let(a, T.any(
                   ^^^^^^^^^^^^^^^ #{MSG}
                Integer,
                String
              ))
            end
          RUBY

          assert_correction(<<~RUBY)
            sig { params(a: T.any(Integer, String)).void }
            def initialize(a)
              @a = a
            end
          RUBY
        end

        # Sorbet's initializer rewriter does not process ivar assignments when
        # the def is wrapped by a method modifier, so T.let remains required.
        def test_no_offense_with_method_modifier_wrapping_def
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            private def initialize(a)
              @a = T.let(a, Integer)
            end
          RUBY
        end
      end
    end
  end
end
