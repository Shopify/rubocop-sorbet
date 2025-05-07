# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class BindingConstantWithoutTypeAliasTest < ::Minitest::Test
        MSG = "Sorbet/BindingConstantWithoutTypeAlias: It looks like you're trying to bind a type to a constant. To do this, you must alias the type using `T.type_alias`."
        DEPRECATION_MSG = "Sorbet/BindingConstantWithoutTypeAlias: It looks like you're using the old `T.type_alias` syntax. `T.type_alias` now expects a block.Run Sorbet with the options \"--autocorrect --error-white-list=5043\" to automatically upgrade to the new syntax."

        def setup
          @cop = BindingConstantWithoutTypeAlias.new
        end

        def test_disallows_binding_return_value_of_t_any_t_all_and_others_without_using_t_type_alias
          assert_offense(<<~RUBY)
            A = T.any(String, Integer)
                ^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            B = T.all(String, Integer)
                ^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            C = T.noreturn
                ^^^^^^^^^^ #{MSG}
            D = T.class_of(String)
                ^^^^^^^^^^^^^^^^^^ #{MSG}
            E = T.proc.void
                ^^^^^^^^^^^ #{MSG}
            F = T.untyped
                ^^^^^^^^^ #{MSG}
            G = T.nilable(String)
                ^^^^^^^^^^^^^^^^^ #{MSG}
            H = T.self_type
                ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            A = T.type_alias { T.any(String, Integer) }
            B = T.type_alias { T.all(String, Integer) }
            C = T.type_alias { T.noreturn }
            D = T.type_alias { T.class_of(String) }
            E = T.type_alias { T.proc.void }
            F = T.type_alias { T.untyped }
            G = T.type_alias { T.nilable(String) }
            H = T.type_alias { T.self_type }
          RUBY
        end

        def test_allows_binding_return_of_t_any_t_all_etc_when_using_t_type_alias
          assert_no_offenses(<<~RUBY)
            A = T.type_alias { T.any(String, Integer) }
            B = T.type_alias { T.all(String, Integer) }
            C = T.type_alias { T.noreturn }
            D = T.type_alias { T.class_of(String) }
            E = T.type_alias { T.proc.void }
            F = T.type_alias { T.untyped }
            G = T.type_alias { T.nilable(String) }
            H = T.type_alias { T.self_type }
          RUBY
        end

        def test_allows_assigning_t_let_to_a_constant
          assert_no_offenses(<<~RUBY)
            A = T.let(None.new, Optional[T.untyped])
            B = T.let(C, T.proc.void)
          RUBY
        end

        def test_allows_assigning_type_member_to_a_constant
          assert_no_offenses(<<~RUBY)
            A = type_member(fixed: T.untyped)
            A = type_member { { fixed: T.class_of(::ActiveRecord::Base) } }
            A = type_member(:in) { { fixed: T.untyped } }
          RUBY
        end

        def test_allows_assigning_type_template_to_a_constant
          assert_no_offenses(<<~RUBY)
            A = type_template(fixed: T.untyped)
            A = type_template { { fixed: T.class_of(::ActiveRecord::Base) } }
            A = type_template(:in) { { fixed: T.untyped } }
          RUBY
        end

        def test_allow_using_class_new_or_module_new_with_extend_t_sig
          assert_no_offenses(<<~RUBY)
            Foo = Class.new do
              A = T.let(42, T.any(Integer, Float))
            end

            Foo2 = Class.new(String) do
              A = T.let(42, T.any(Integer, Float))
            end

            Bar = Module.new do
              A = T.let(42, T.any(Integer, Float))
            end

            Baz = Struct.new do
              A = T.let(42, T.any(Integer, Float))
            end

            Baz2 = Struct.new(:baz) do
              A = T.let(42, T.any(Integer, Float))
            end

            Baz3 = Struct.new(:baz, :bar, :foo) do
              A = T.let(42, T.any(Integer, Float))
            end
          RUBY
        end

        def test_allows_using_return_value_of_t_any_t_all_etc_in_signature_definition
          assert_no_offenses(<<~RUBY)
            sig { params(foo: T.any(String, Integer)).void }
            def a(foo); end

            sig { params(foo: T.all(String, Integer)).void }
            def b(foo); end

            sig { returns(T.noreturn) }
            def c; end

            sig { params(foo: T.class_of(String)).void }
            def d(foo); end

            sig { params(foo: T.proc.void).void }
            def e(foo); end

            sig { params(foo: T.untyped).void }
            def f(foo); end

            sig { params(foo: T.nilable(String)).void }
            def g(foo); end

            sig { params(foo: T.self_type).void }
            def h(foo); end
          RUBY
        end

        def test_doesnt_crash_when_assigning_constants_by_destructuring
          assert_no_offenses(<<~RUBY)
            A, B = [1, 2]
          RUBY
        end

        def test_disallows_usage_of_old_t_type_alias_syntax
          assert_offense(<<~RUBY)
            A = T.type_alias(T.any(String, Integer))
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{DEPRECATION_MSG}
            B = T.type_alias(T.all(String, Integer))
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{DEPRECATION_MSG}
            C = T.type_alias(T.noreturn)
                ^^^^^^^^^^^^^^^^^^^^^^^^ #{DEPRECATION_MSG}
            D = T.type_alias(T.class_of(String))
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{DEPRECATION_MSG}
            E = T.type_alias(T.proc.void)
                ^^^^^^^^^^^^^^^^^^^^^^^^^ #{DEPRECATION_MSG}
            F = T.type_alias(T.untyped)
                ^^^^^^^^^^^^^^^^^^^^^^^ #{DEPRECATION_MSG}
            G = T.type_alias(T.nilable(String))
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{DEPRECATION_MSG}
            H = T.type_alias(T.self_type)
                ^^^^^^^^^^^^^^^^^^^^^^^^^ #{DEPRECATION_MSG}
          RUBY

          assert_correction(<<~RUBY)
            A = T.type_alias { T.any(String, Integer) }
            B = T.type_alias { T.all(String, Integer) }
            C = T.type_alias { T.noreturn }
            D = T.type_alias { T.class_of(String) }
            E = T.type_alias { T.proc.void }
            F = T.type_alias { T.untyped }
            G = T.type_alias { T.nilable(String) }
            H = T.type_alias { T.self_type }
          RUBY
        end
      end
    end
  end
end
