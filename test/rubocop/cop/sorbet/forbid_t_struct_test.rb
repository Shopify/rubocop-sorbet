# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTStructTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTStruct: Using `T::Struct` or its variants is deprecated in this codebase."
        PROPS_MSG = "Sorbet/ForbidTStruct: Using `T::Props` or its variants is deprecated in this codebase."

        def setup
          @cop = ForbidTStruct.new
        end

        def test_registers_offense_when_inheriting_t_struct_on_multiline_class
          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_registers_offense_when_inheriting_t_struct_on_singleline_class
          assert_offense(<<~RUBY)
            class Foo < T::Struct; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_registers_offense_when_inheriting_fully_qualified_t_struct
          assert_offense(<<~RUBY)
            class Foo < ::T::Struct; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_registers_offense_when_inheriting_t_immutable_struct
          assert_offense(<<~RUBY)
            class Foo < T::ImmutableStruct
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_registers_offense_when_inheriting_t_inexact_struct
          assert_offense(<<~RUBY)
            class Foo < T::InexactStruct
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_registers_offense_when_including_anything_related_to_t_props
          assert_offense(<<~RUBY)
            class Foo
              include T::Props
              ^^^^^^^^^^^^^^^^ #{PROPS_MSG}
              include T::Props::Constructor
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{PROPS_MSG}
              include T::Props::WeakConstructor
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{PROPS_MSG}
              prepend T::Props::Foo
              ^^^^^^^^^^^^^^^^^^^^^ #{PROPS_MSG}
              extend T::Props::Bar
              ^^^^^^^^^^^^^^^^^^^^ #{PROPS_MSG}
              extend ::T::Props
              ^^^^^^^^^^^^^^^^^ #{PROPS_MSG}
            end
          RUBY
        end

        def test_registers_offense_for_nested_structs
          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              class Bar < T::Struct
              ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            end
          RUBY
        end

        def test_does_not_register_offense_when_not_using_t_struct
          assert_no_offenses(<<~RUBY)
            class Foo
            end

            class Bar < Baz; end

            class Baz
              extend T::Struct
            end

            class T::Struct; end
          RUBY
        end

        def test_autocorrects_t_struct_to_bare_class
          assert_offense(<<~RUBY)
            class Foo < T::Struct; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            class Foo; end
          RUBY
        end

        def test_autocorrects_generates_bare_class_body
          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              const :foo, Integer
              prop :bar, String, default: "foo"
              const :baz, T.nilable(Symbol), factory: ->{ nil }
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              extend T::Sig

              sig { returns(Integer) }
              attr_reader :foo

              sig { returns(String) }
              attr_accessor :bar

              sig { returns(T.nilable(Symbol)) }
              attr_reader :baz

              sig { params(foo: Integer, bar: String, baz: T.nilable(Symbol)).void }
              def initialize(foo:, bar: "foo", baz: ->{ nil })
                @foo = foo
                @bar = bar
                @baz = baz.call
              end
            end
          RUBY
        end

        def test_autocorrects_generates_initialize_parameters_in_correct_order
          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              const :foo, Integer
              prop :bar, String, default: "foo"
              const :baz, Symbol
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              extend T::Sig

              sig { returns(Integer) }
              attr_reader :foo

              sig { returns(String) }
              attr_accessor :bar

              sig { returns(Symbol) }
              attr_reader :baz

              sig { params(foo: Integer, baz: Symbol, bar: String).void }
              def initialize(foo:, baz:, bar: "foo")
                @foo = foo
                @bar = bar
                @baz = baz
              end
            end
          RUBY
        end

        def test_autocorrects_keeps_other_nodes_in_body
          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              CONST = 42

              const :foo, Integer

              @foo = 42

              # Some comment
              sig { params(x: Integer).returns(String) }
              def foo(x)
                "foo" * x
              end

              private

              sig do
                void
              end
              def self.bar; end

              class << self
                def bar; end
              end

              # Another comment
              class Bar
                class Baz; end
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              extend T::Sig

              CONST = 42

              sig { returns(Integer) }
              attr_reader :foo

              sig { params(foo: Integer).void }
              def initialize(foo:)
                @foo = foo
              end

              @foo = 42

              # Some comment
              sig { params(x: Integer).returns(String) }
              def foo(x)
                "foo" * x
              end

              private

              sig do
                void
              end
              def self.bar; end

              class << self
                def bar; end
              end

              # Another comment
              class Bar
                class Baz; end
              end
            end
          RUBY
        end
      end
    end
  end
end
