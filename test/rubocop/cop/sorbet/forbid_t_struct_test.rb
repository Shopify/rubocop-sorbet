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

        def test_autocorrects_when_layout_line_length_is_disabled
          # When Layout/LineLength is disabled, max_line_length returns nil.
          # This should not cause a crash and should default to single-line formatting.
          @config = RuboCop::Config.new(
            "Sorbet/ForbidTStruct" => { "Enabled" => true, "AutoCorrect" => "always" },
            "Layout/LineLength" => { "Enabled" => false },
          )
          @cop = ForbidTStruct.new(@config)

          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
              const :foo, Integer
              prop :bar, String, default: "foo"
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              extend T::Sig

              sig { returns(Integer) }
              attr_reader :foo

              sig { returns(String) }
              attr_accessor :bar

              sig { params(foo: Integer, bar: String).void }
              def initialize(foo:, bar: "foo")
                @foo = foo
                @bar = bar
              end
            end
          RUBY
        end

        def test_autocorrects_generates_rbs_class_body
          @cop = ForbidTStruct.new(cop_config("AutocorrectStyle" => "rbs"))

          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
              const :foo, Integer
              prop :bar, String, default: "foo"
              const :baz, T.nilable(Symbol), factory: ->{ nil }
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              #: Integer
              attr_reader :foo

              #: String
              attr_accessor :bar

              #: Symbol?
              attr_reader :baz

              #: (foo: Integer, ?bar: String, ?baz: Symbol?) -> void
              def initialize(foo:, bar: "foo", baz: ->{ nil })
                @foo = foo
                @bar = bar
                @baz = baz.call
              end
            end
          RUBY
        end

        def test_autocorrects_rbs_translates_sorbet_types
          @cop = ForbidTStruct.new(cop_config("AutocorrectStyle" => "rbs"))

          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
              const :a, T.any(Integer, String)
              const :b, T::Array[String]
              const :c, T::Hash[Symbol, Integer]
              const :d, T.all(Comparable, Numeric)
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              #: (Integer | String)
              attr_reader :a

              #: Array[String]
              attr_reader :b

              #: Hash[Symbol, Integer]
              attr_reader :c

              #: (Comparable & Numeric)
              attr_reader :d

              #: (a: (Integer | String), b: Array[String], c: Hash[Symbol, Integer], d: (Comparable & Numeric)) -> void
              def initialize(a:, b:, c:, d:)
                @a = a
                @b = b
                @c = c
                @d = d
              end
            end
          RUBY
        end

        def test_autocorrects_rbs_maps_sorbet_constants
          @cop = ForbidTStruct.new(cop_config("AutocorrectStyle" => "rbs"))

          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
              const :a, T::Boolean
              const :b, T::Range[Integer]
              const :c, T::Hash[Symbol, T::Boolean]
              const :d, T::Enumerable[Integer]
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              #: bool
              attr_reader :a

              #: Range[Integer]
              attr_reader :b

              #: Hash[Symbol, bool]
              attr_reader :c

              #: Enumerable[Integer]
              attr_reader :d

              #: (a: bool, b: Range[Integer], c: Hash[Symbol, bool], d: Enumerable[Integer]) -> void
              def initialize(a:, b:, c:, d:)
                @a = a
                @b = b
                @c = c
                @d = d
              end
            end
          RUBY
        end

        def test_autocorrects_rbs_translates_special_types
          @cop = ForbidTStruct.new(cop_config("AutocorrectStyle" => "rbs"))

          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
              const :a, T.untyped
              const :b, T.class_of(Foo)
              const :c, T.proc.params(x: Integer).returns(String)
              const :d, T.noreturn
              const :e, T.something_weird(Integer)
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              #: untyped
              attr_reader :a

              #: singleton(Foo)
              attr_reader :b

              #: ^(Integer x) -> String
              attr_reader :c

              #: bot
              attr_reader :d

              #: untyped
              attr_reader :e

              #: (a: untyped, b: singleton(Foo), c: ^(Integer x) -> String, d: bot, e: untyped) -> void
              def initialize(a:, b:, c:, d:, e:)
                @a = a
                @b = b
                @c = c
                @d = d
                @e = e
              end
            end
          RUBY
        end

        def test_autocorrects_rbs_translates_nested_nilable_union
          @cop = ForbidTStruct.new(cop_config("AutocorrectStyle" => "rbs"))

          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
              const :a, T.nilable(T.any(Integer, String))
              const :b, Integer
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              #: (Integer | String)?
              attr_reader :a

              #: Integer
              attr_reader :b

              #: (b: Integer, ?a: (Integer | String)?) -> void
              def initialize(b:, a: nil)
                @a = a
                @b = b
              end
            end
          RUBY
        end

        def test_autocorrects_rbs_removes_existing_extend_t_sig
          @cop = ForbidTStruct.new(cop_config("AutocorrectStyle" => "rbs"))

          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
              extend T::Sig
              const :foo, Integer
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              #: Integer
              attr_reader :foo

              #: (foo: Integer) -> void
              def initialize(foo:)
                @foo = foo
              end
            end
          RUBY
        end

        def test_autocorrects_rbs_keeps_other_nodes_in_body
          @cop = ForbidTStruct.new(cop_config("AutocorrectStyle" => "rbs"))

          assert_offense(<<~RUBY)
            class Foo < T::Struct
            ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
              const :foo, Integer

              def some_method; end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              #: Integer
              attr_reader :foo

              #: (foo: Integer) -> void
              def initialize(foo:)
                @foo = foo
              end

              def some_method; end
            end
          RUBY
        end

        def test_invalid_autocorrect_style_raises_error
          @cop = ForbidTStruct.new(cop_config("AutocorrectStyle" => "invalid"))

          error = assert_raises(ArgumentError) do
            assert_offense(<<~RUBY)
              class Foo < T::Struct
              ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
                const :foo, Integer
              end
            RUBY
          end
          assert_match(/Invalid AutocorrectStyle option/, error.message)
        end

        private

        def target_cop
          ForbidTStruct
        end
      end
    end
  end
end
