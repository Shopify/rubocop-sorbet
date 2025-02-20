# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidTStruct, :config) do
  describe("Offenses") do
    it "adds offense when inheriting T::Struct on a multiline class" do
      expect_offense(<<~RUBY)
        class Foo < T::Struct
        ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
        end
      RUBY
    end

    it "adds offense when inheriting T::Struct on a singleline class" do
      expect_offense(<<~RUBY)
        class Foo < T::Struct; end
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
      RUBY
    end

    it "adds offense when inheriting ::T::Struct" do
      expect_offense(<<~RUBY)
        class Foo < ::T::Struct; end
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
      RUBY
    end

    it "adds offense when inheriting T::ImmutableStruct" do
      expect_offense(<<~RUBY)
        class Foo < T::ImmutableStruct
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
        end
      RUBY
    end

    it "adds offense when inheriting T::InexactStruct" do
      expect_offense(<<~RUBY)
        class Foo < T::InexactStruct
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
        end
      RUBY
    end

    it "adds offense when including anything related to T::Props" do
      expect_offense(<<~RUBY)
        class Foo
          include T::Props
          ^^^^^^^^^^^^^^^^ Using `T::Props` or its variants is deprecated in this codebase.
          include T::Props::Constructor
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `T::Props` or its variants is deprecated in this codebase.
          include T::Props::WeakConstructor
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Using `T::Props` or its variants is deprecated in this codebase.
          prepend T::Props::Foo
          ^^^^^^^^^^^^^^^^^^^^^ Using `T::Props` or its variants is deprecated in this codebase.
          extend T::Props::Bar
          ^^^^^^^^^^^^^^^^^^^^ Using `T::Props` or its variants is deprecated in this codebase.
          extend ::T::Props
          ^^^^^^^^^^^^^^^^^ Using `T::Props` or its variants is deprecated in this codebase.
        end
      RUBY
    end

    it "adds offense for nested structs" do
      expect_offense(<<~RUBY)
        class Foo < T::Struct
        ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
          class Bar < T::Struct
          ^^^^^^^^^^^^^^^^^^^^^ Using `T::Struct` or its variants is deprecated in this codebase.
          end
        end
      RUBY
    end
  end

  describe("No offenses") do
    it "does not add offense when not using T::Struct" do
      expect_no_offenses(<<~RUBY)
        class Foo
        end

        class Bar < Baz; end

        class Baz
          extend T::Struct
        end

        class T::Struct; end
      RUBY
    end
  end

  describe("Autocorrect") do
    it "changes T::Struct to a bare class" do
      source = <<~RUBY
        class Foo < T::Struct; end
      RUBY

      corrected = <<~RUBY
        class Foo; end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "generates the bare class body" do
      source = <<~RUBY
        class Foo < T::Struct
          const :foo, Integer
          prop :bar, String, default: "foo"
          const :baz, T.nilable(Symbol), factory: ->{ nil }
        end
      RUBY

      corrected = <<~RUBY
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

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "generates initialize parameters in the correct order" do
      source = <<~RUBY
        class Foo < T::Struct
          const :foo, Integer
          prop :bar, String, default: "foo"
          const :baz, Symbol
        end
      RUBY

      corrected = <<~RUBY
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

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "keeps other nodes in the body" do
      source = <<~RUBY
        class Foo < T::Struct
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

      corrected = <<~RUBY
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

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "preserves the right indent" do
      source = <<~RUBY
        module Bar
          class Foo < T::Struct
            const :foo, Integer

            def bar; end
          end
        end
      RUBY

      corrected = <<~RUBY
        module Bar
          class Foo
            extend T::Sig

            sig { returns(Integer) }
            attr_reader :foo

            sig { params(foo: Integer).void }
            def initialize(foo:)
              @foo = foo
            end

            def bar; end
          end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "does not duplicate extend T::Sig" do
      source = <<~RUBY
        class Foo < T::Struct
          extend T::Sig

          const :foo, Integer

          def bar; end
        end
      RUBY

      corrected = <<~RUBY
        class Foo
          extend T::Sig

          sig { returns(Integer) }
          attr_reader :foo

          sig { params(foo: Integer).void }
          def initialize(foo:)
            @foo = foo
          end

          def bar; end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "preserves right blank lines between properties" do
      source = <<~RUBY
        class Foo < T::Struct
          const :foo, Integer

          prop :bar, String
        end
      RUBY

      corrected = <<~RUBY
        class Foo
          extend T::Sig

          sig { returns(Integer) }
          attr_reader :foo

          sig { returns(String) }
          attr_accessor :bar

          sig { params(foo: Integer, bar: String).void }
          def initialize(foo:, bar:)
            @foo = foo
            @bar = bar
          end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "preserves comments on properties" do
      source = <<~RUBY
        class Foo < T::Struct
          # Some comment here
          const :foo, Integer
          prop :bar, String # Another comment here

          # Some loose comment after
        end
      RUBY

      corrected = <<~RUBY
        class Foo
          extend T::Sig

          # Some comment here
          sig { returns(Integer) }
          attr_reader :foo

          # Another comment here
          sig { returns(String) }
          attr_accessor :bar

          sig { params(foo: Integer, bar: String).void }
          def initialize(foo:, bar:)
            @foo = foo
            @bar = bar
          end

          # Some loose comment after
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "handles optional nilable properties" do
      source = <<~RUBY
        class Foo < T::Struct
          const :foo, T.nilable(Integer)
          prop :bar, T.nilable(String)
          prop :baz, Integer
        end
      RUBY

      corrected = <<~RUBY
        class Foo
          extend T::Sig

          sig { returns(T.nilable(Integer)) }
          attr_reader :foo

          sig { returns(T.nilable(String)) }
          attr_accessor :bar

          sig { returns(Integer) }
          attr_accessor :baz

          sig { params(baz: Integer, foo: T.nilable(Integer), bar: T.nilable(String)).void }
          def initialize(baz:, foo: nil, bar: nil)
            @foo = foo
            @bar = bar
            @baz = baz
          end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "handles spaces in types" do
      source = <<~RUBY
        class Foo < T::Struct
          const :foo, T.any(Integer, String)
          const :bar, T.nilable(
            T.any(Integer, String)
          )
          const :baz, T::Hash[Integer, String]
          const :qux, T::Hash[Symbol, T.any(Integer, String)]
          const :quux, T.any(
            T::Hash[Integer, String],
            String
          )
        end
      RUBY

      corrected = <<~RUBY
        class Foo
          extend T::Sig

          sig { returns(T.any(Integer, String)) }
          attr_reader :foo

          sig { returns(T.nilable(T.any(Integer, String))) }
          attr_reader :bar

          sig { returns(T::Hash[Integer, String]) }
          attr_reader :baz

          sig { returns(T::Hash[Symbol, T.any(Integer, String)]) }
          attr_reader :qux

          sig { returns(T.any(T::Hash[Integer, String], String)) }
          attr_reader :quux

          sig do
            params(
              foo: T.any(Integer, String),
              baz: T::Hash[Integer, String],
              qux: T::Hash[Symbol, T.any(Integer, String)],
              quux: T.any(T::Hash[Integer, String], String),
              bar: T.nilable(T.any(Integer, String))
            ).void
          end
          def initialize(foo:, baz:, qux:, quux:, bar: nil)
            @foo = foo
            @bar = bar
            @baz = baz
            @qux = qux
            @quux = quux
          end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "strips new lines from type definitions" do
      source = <<~RUBY
        class Foo < T::Struct
          const :foo, T.nilable(
            Integer
          )
        end
      RUBY

      corrected = <<~RUBY
        class Foo
          extend T::Sig

          sig { returns(T.nilable(Integer)) }
          attr_reader :foo

          sig { params(foo: T.nilable(Integer)).void }
          def initialize(foo: nil)
            @foo = foo
          end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected))
    end

    it "splits long lines" do
      source = <<~RUBY
        class Foo < T::Struct
          const :foo, LONG_CONSTANT_NAME_WITH_MANY_CHARS, default: LONG_CONSTANT_NAME_WITH_MANY_CHARS
          const :bar, LONG_CONSTANT_NAME_WITH_MANY_CHARS, default: LONG_CONSTANT_NAME_WITH_MANY_CHARS
          const :baz, LONG_CONSTANT_NAME_WITH_MANY_CHARS, default: LONG_CONSTANT_NAME_WITH_MANY_CHARS
          const :qux, LONG_CONSTANT_NAME_WITH_MANY_CHARS, default: LONG_CONSTANT_NAME_WITH_MANY_CHARS
        end
      RUBY

      corrected = <<~RUBY
        class Foo
          extend T::Sig

          sig { returns(LONG_CONSTANT_NAME_WITH_MANY_CHARS) }
          attr_reader :foo

          sig { returns(LONG_CONSTANT_NAME_WITH_MANY_CHARS) }
          attr_reader :bar

          sig { returns(LONG_CONSTANT_NAME_WITH_MANY_CHARS) }
          attr_reader :baz

          sig { returns(LONG_CONSTANT_NAME_WITH_MANY_CHARS) }
          attr_reader :qux

          sig do
            params(
              foo: LONG_CONSTANT_NAME_WITH_MANY_CHARS,
              bar: LONG_CONSTANT_NAME_WITH_MANY_CHARS,
              baz: LONG_CONSTANT_NAME_WITH_MANY_CHARS,
              qux: LONG_CONSTANT_NAME_WITH_MANY_CHARS
            ).void
          end
          def initialize(
            foo: LONG_CONSTANT_NAME_WITH_MANY_CHARS,
            bar: LONG_CONSTANT_NAME_WITH_MANY_CHARS,
            baz: LONG_CONSTANT_NAME_WITH_MANY_CHARS,
            qux: LONG_CONSTANT_NAME_WITH_MANY_CHARS
          )
            @foo = foo
            @bar = bar
            @baz = baz
            @qux = qux
          end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected))
    end
  end
end
