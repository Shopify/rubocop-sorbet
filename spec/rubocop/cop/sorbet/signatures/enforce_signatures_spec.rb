# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::EnforceSignatures, :config) do
  describe("require a signature for each method") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "AllowRBS" => true,
      }
    end

    it "makes no offense if a top-level method has a signature" do
      expect_no_offenses(<<~RUBY)
        sig { void }
        def foo; end
      RUBY
    end

    it "makes no offense if a top-level method has an RBS signature" do
      expect_no_offenses(<<~RUBY)
        #: -> void
        def foo; end
      RUBY
    end

    it "makes no offense if a top-level method has a signature" do
      expect_no_offenses(<<~RUBY)
        sig(:final) { void }
        def foo; end
      RUBY
    end

    it "makes offense if a top-level method has no signature" do
      expect_offense(<<~RUBY)
        def foo; end
        ^^^^^^^^^^^^ Each method is required to have a signature.
      RUBY
    end

    it "does not check signature validity" do # Validity will be checked by Sorbet
      expect_no_offenses(<<~RUBY)
        sig { foo(bar).baz }
        def foo; end
      RUBY
    end

    it "does not check RBS signature validity" do
      expect_no_offenses(<<~RUBY)
        #: hello world
        def foo; end
      RUBY
    end

    it "makes no offense if a method has a signature" do
      expect_no_offenses(<<~RUBY)
        class Foo
          sig { void }
          def foo1; end
        end
      RUBY
    end

    it "makes no offense if a method has a RBS signature" do
      expect_no_offenses(<<~RUBY)
        class Foo
          #: -> void
          def foo1; end
        end
      RUBY
    end

    it "makes offense if a method has no signature" do
      expect_offense(<<~RUBY)
        class Foo
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        end
      RUBY
    end

    it "registers no offenses on signature overloads" do
      expect_no_offenses(<<~RUBY)
        class Foo
          sig { void }
          sig { void }
          sig { void }
          sig { void }
          sig { void }
          def foo; end
        end

        sig { void }
        sig { void }
        def foo; end
      RUBY
    end

    it "registers offenses even when methods with the same name have sigs in other scopes" do
      expect_offense(<<~RUBY)
        module Foo
          sig { void }
        end

        class Bar
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.

          sig { void }
        end

        def foo; end
        ^^^^^^^^^^^^ Each method is required to have a signature.

        class Baz
          sig { void }
          def foo; end

          def baz; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        end

        foo do
          sig { void }
          def foo; end

          def baz; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        end

        foo do
          sig { void }
        end

        foo do
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        end
      RUBY
    end

    it "registers offenses even when methods with the same name have RBS sigs in other scopes" do
      expect_offense(<<~RUBY)
        module Foo
          #: -> void
        end

        class Bar
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.

          #: -> void
        end

        def foo; end
        ^^^^^^^^^^^^ Each method is required to have a signature.

        class Baz
          #: -> void
          def foo; end

          def baz; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        end

        foo do
          #: -> void
          def foo; end

          def baz; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        end

        foo do
          #: -> void
        end

        foo do
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        end
      RUBY
    end

    it "makes no offense if a singleton method has a signature" do
      expect_no_offenses(<<~RUBY)
        class Foo
          sig { void }
          def self.foo1; end
        end
      RUBY
    end

    it "makes no offense if a singleton method has an RBS signature" do
      expect_no_offenses(<<~RUBY)
        class Foo
          #: -> void
          def self.foo1; end
        end
      RUBY
    end

    it "makes offense if a singleton method has no signature" do
      expect_offense(<<~RUBY)
        class Foo
          def self.foo; end
          ^^^^^^^^^^^^^^^^^ Each method is required to have a signature.
        end
      RUBY
    end

    it "makes no offense if an accessor has a signature" do
      expect_no_offenses(<<~RUBY)
        class Foo
          sig { returns(String) }
          attr_reader :foo
          sig { params(bar: String).void }
          attr_writer :bar
          sig { params(bar: String).returns(String) }
          attr_accessor :baz
        end
      RUBY
    end

    it "makes no offense if an accessor has an RBS signature" do
      expect_no_offenses(<<~RUBY)
        class Foo
          #: -> String
          attr_reader :foo
          #: (String) -> void
          attr_writer :bar
          #: (String) -> String
          attr_accessor :baz
        end
      RUBY
    end

    it "makes offense if an accessor has no signature" do
      expect_offense(<<~RUBY)
        class Foo
          attr_reader :foo
          ^^^^^^^^^^^^^^^^ Each method is required to have a signature.
          attr_writer :bar
          ^^^^^^^^^^^^^^^^ Each method is required to have a signature.
          attr_accessor :baz
          ^^^^^^^^^^^^^^^^^^ Each method is required to have a signature.
        end
      RUBY
    end

    it "makes no offense if the signature is declared with T::Sig::WithoutRuntime.sig" do
      expect_no_offenses(<<~RUBY)
        class Foo
          T::Sig::WithoutRuntime.sig { void }
          def foo; end
        end
      RUBY
    end

    it "makes no offense if the signature is declared with T::Sig.sig" do
      expect_no_offenses(<<~RUBY)
        class Foo
          T::Sig.sig { void }
          def foo; end
        end
      RUBY
    end

    it "makes offense if the signature on an unknown receiver" do
      expect_offense(<<~RUBY)
        class Foo
          T::Sig::WithRuntime.sig { void }
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.

          T::SomeSig.sig { void }
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.

          Sig.sig { void }
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        end
      RUBY
    end

    it "makes no offense if method has a comment separating RBS signature" do
      expect_no_offenses(<<~RUBY)
        # before
        #: -> void
        # after
        def foo; end
      RUBY
    end

    it "makes offense if method has a blank line separating RBS signature" do
      expect_offense(<<~RUBY)
        #: -> void

        def foo; end
        ^^^^^^^^^^^^ Each method is required to have a signature.
      RUBY
    end

    it "does not check the signature for accessors" do # Validity will be checked by Sorbet
      expect_no_offenses(<<~RUBY)
        class Foo
          sig { void }
          attr_reader :foo, :bar
        end
      RUBY
    end

    it "does not check the RBS signature for accessors" do # Validity will be checked by Sorbet
      expect_no_offenses(<<~RUBY)
        class Foo
          #: -> void
          attr_reader :foo, :bar
        end
      RUBY
    end

    it("supports visibility modifiers") do
      expect_no_offenses(<<~RUBY)
        sig { void }
        private def foo; end

        sig { void }
        public def foo; end

        sig { void }
        protected def foo; end

        sig { void }
        foo bar baz def foo; end
      RUBY
    end

    it("supports visibility modifiers for RBS signatures") do
      expect_no_offenses(<<~RUBY)
        #: -> void
        private def foo; end

        #: -> void
        public def foo; end

        #: -> void
        protected def foo; end

        #: -> void
        foo bar baz def foo; end
      RUBY
    end

    shared_examples_for("autocorrect with config") do
      it("autocorrects methods by adding signature stubs") do
        expect(
          autocorrect_source(<<~RUBY),
            def foo; end
            def bar(a, b = 2, c: Foo.new); end
            def baz(&blk); end
            def self.foo(a, b, &c); end
            def self.bar(a, *b, **c); end
            def self.baz(a:); end
          RUBY
        ).to(eq(<<~RUBY))
          sig { returns(T.untyped) }
          def foo; end
          sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
          def bar(a, b = 2, c: Foo.new); end
          sig { params(blk: T.untyped).returns(T.untyped) }
          def baz(&blk); end
          sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
          def self.foo(a, b, &c); end
          sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
          def self.bar(a, *b, **c); end
          sig { params(a: T.untyped).returns(T.untyped) }
          def self.baz(a:); end
        RUBY
      end

      it("autocorrects accessors by adding signature stubs") do
        expect(
          autocorrect_source(<<~RUBY),
            class Foo
              attr_reader :foo
              attr_writer :bar
              attr_accessor :baz
            end
          RUBY
        ).to(eq(<<~RUBY))
          class Foo
            sig { returns(T.untyped) }
            attr_reader :foo
            sig { params(bar: T.untyped).void }
            attr_writer :bar
            sig { params(baz: T.untyped).returns(T.untyped) }
            attr_accessor :baz
          end
        RUBY
      end
    end

    describe("AllowRBS = false") do
      let(:cop_config) do
        {
          "Enabled" => true,
          "AllowRBS" => false,
        }
      end

      it("makes offense if AllowRBS false") do
        expect_offense(<<~RUBY)
          #: -> void
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        RUBY
      end
    end

    describe("autocorrect") do
      it_should_behave_like "autocorrect with config"
    end

    describe("autocorrect with default values") do
      let(:cop_config) do
        {
          "Enabled" => true,
          "ParameterTypePlaceholder" => "T.untyped",
          "ReturnTypePlaceholder" => "T.untyped",
        }
      end
      it_should_behave_like "autocorrect with config"
    end

    describe("autocorrect with custom values") do
      let(:cop_config) do
        {
          "Enabled" => true,
          "ParameterTypePlaceholder" => "PARAM",
          "ReturnTypePlaceholder" => "RET",
        }
      end

      it("autocorrects methods by adding signature stubs") do
        expect(
          autocorrect_source(<<~RUBY),
            def foo; end
            def bar(a, b = 2, c: Foo.new); end
            def baz(&blk); end

            class Foo
              def foo
              end

              def bar(a, b, c)
              end
            end
          RUBY
        ).to(eq(<<~RUBY))
          sig { returns(RET) }
          def foo; end
          sig { params(a: PARAM, b: PARAM, c: PARAM).returns(RET) }
          def bar(a, b = 2, c: Foo.new); end
          sig { params(blk: PARAM).returns(RET) }
          def baz(&blk); end

          class Foo
            sig { returns(RET) }
            def foo
            end

            sig { params(a: PARAM, b: PARAM, c: PARAM).returns(RET) }
            def bar(a, b, c)
            end
          end
        RUBY
      end

      it("autocorrects accessors by adding signature stubs") do
        expect(
          autocorrect_source(<<~RUBY),
            class Foo
              attr_reader :foo
              attr_writer :bar
              attr_accessor :baz
            end
          RUBY
        ).to(eq(<<~RUBY))
          class Foo
            sig { returns(RET) }
            attr_reader :foo
            sig { params(bar: PARAM).void }
            attr_writer :bar
            sig { params(baz: PARAM).returns(RET) }
            attr_accessor :baz
          end
        RUBY
      end
    end
  end
end
