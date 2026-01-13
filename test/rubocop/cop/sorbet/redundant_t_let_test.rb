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
      end
    end
  end
end
