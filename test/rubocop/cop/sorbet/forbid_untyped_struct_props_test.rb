# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidUntypedStructPropsTest < ::Minitest::Test
        MSG = "Sorbet/ForbidUntypedStructProps: Struct props cannot be T.untyped"

        def setup
          @cop = ForbidUntypedStructProps.new
        end

        def test_adds_offense_when_const_is_t_untyped
          assert_offense(<<~RUBY)
            class MyClass < T::Struct
              const :foo, T.untyped
                          ^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_adds_offense_when_const_is_t_untyped_in_immutable_struct
          assert_offense(<<~RUBY)
            class MyClass < T::ImmutableStruct
              const :foo, T.untyped
                          ^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_adds_offense_when_const_is_t_nilable_t_untyped
          assert_offense(<<~RUBY)
            class MyClass < T::Struct
              const :foo, T.nilable(T.untyped)
                          ^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_adds_offense_when_prop_is_t_untyped
          assert_offense(<<~RUBY)
            class MyClass < T::Struct
              prop :foo, T.untyped
                         ^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_adds_offense_when_prop_is_t_nilable_t_untyped
          assert_offense(<<~RUBY)
            class MyClass < T::Struct
              prop :foo, T.nilable(T.untyped)
                         ^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_adds_offense_when_prop_is_t_nilable_t_untyped_and_has_other_options
          assert_offense(<<~RUBY)
            class MyClass < T::Struct
              prop :foo, T.nilable(T.untyped), immutable: true
                         ^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_adds_offense_when_multiple_props_are_untyped
          assert_offense(<<~RUBY)
            class MyClass < T::Struct
              const :foo, T.untyped
                          ^^^^^^^^^ #{MSG}
              const :nilable_foo, T.nilable(T.untyped)
                                  ^^^^^^^^^^^^^^^^^^^^ #{MSG}
              const :nested_foo, T.nilable(T.nilable(T.untyped))
                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              prop :bar, T.untyped
                         ^^^^^^^^^ #{MSG}
              prop :nilable_bar, T.nilable(T.untyped)
                                 ^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_does_not_add_offense_when_class_is_not_subclass_of_t_struct
          assert_no_offenses(<<~RUBY)
            class MyClass < SomethingElse
              const :foo, Integer
              const :nilable_foo, T.nilable(String)
              prop :bar, Date
              prop :nilable_bar, T.nilable(Float)
            end
          RUBY
        end

        def test_does_not_add_offense_when_props_have_types
          assert_no_offenses(<<~RUBY)
            class MyClass < T::Struct
              const :foo, Integer
              const :nilable_foo, T.nilable(String)
              prop :bar, Date
              prop :nilable_bar, T.nilable(Float)
              const :array, T::Array[T.untyped]
              const :hash, T::Hash[T.untyped, T.untyped]
            end
          RUBY
        end
      end
    end
  end
end
