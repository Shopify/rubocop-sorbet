# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::EmptyLineAfterSig, :config) do
  context("with no empty line between sig and method definition") do
    it("does not register an offense") do
      expect_no_offenses(<<~RUBY)
        sig { void }
        def foo; end
      RUBY
    end

    it("does not register an offense for surrounding empty lines") do
      expect_no_offenses(<<~RUBY)
        extend T::Sig

        sig { void }
        def foo; end

        bar!
      RUBY
    end

    it("does not register an offense or fail if the sig and definition are on the same line") do
      expect_no_offenses(<<~RUBY)
        sig { void }; def foo; end
      RUBY
    end

    it("does not register an offense or fail if a method definition has multiple sigs (e.g. RBI files)") do
      expect_no_offenses(<<~RUBY)
        sig { void }
        sig { params(foo: String).void }
        def bar(foo); end
      RUBY
    end
  end

  context("with an empty line between sig and method definition") do
    it("registers an offense for normal method definition") do
      expect_offense(<<~RUBY)
        sig { void }

        ^{} Extra empty line or comment detected
        def foo; end
      RUBY

      expect_correction(<<~RUBY)
        sig { void }
        def foo; end
      RUBY
    end

    it("registers an offense for singleton method definition") do
      expect_offense(<<~RUBY)
        sig { void }

        ^{} Extra empty line or comment detected
        def self.foo; end
      RUBY

      expect_correction(<<~RUBY)
        sig { void }
        def self.foo; end
      RUBY
    end

    it("registers an offense for attr_reader") do
      expect_offense(<<~RUBY)
        sig { void }

        ^{} Extra empty line or comment detected
        attr_reader :bar
      RUBY

      expect_correction(<<~RUBY)
        sig { void }
        attr_reader :bar
      RUBY
    end

    it("registers an offense for multiline sigs with indentation") do
      expect_offense(<<~RUBY)
        module Example
          extend T::Sig

          sig do
            params(
              session: String,
            ).void
          end

        ^{} Extra empty line or comment detected
          def initialize(
            session:
          )
            @session = session
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        module Example
          extend T::Sig

          sig do
            params(
              session: String,
            ).void
          end
          def initialize(
            session:
          )
            @session = session
          end
        end
      RUBY
    end

    it("registers an offense for comments in between sig and method definition") do
      expect_offense(<<~RUBY)
        module Example
          extend T::Sig

          sig do
            params(
              session: String,
            ).void
          end
          # Session: string
        ^^^^^^^^^^^^^^^^^^^ Extra empty line or comment detected
          def initialize(
            session:
          )
            @session = session
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        module Example
          extend T::Sig

          # Session: string
          sig do
            params(
              session: String,
            ).void
          end
          def initialize(
            session:
          )
            @session = session
          end
        end
      RUBY
    end

    it "registers an offense for empty line and comments in between sig and method definition" do
      expect_offense(<<~RUBY)
        sig { params(session: String).void }

        ^{} Extra empty line or comment detected

        # Session: string

        # More stuff

        # on more lines

        def initialize(session:)
          @session = session
        end
      RUBY

      expect_correction(<<~RUBY)
        # Session: string
        # More stuff
        # on more lines
        sig { params(session: String).void }
        def initialize(session:)
          @session = session
        end
      RUBY
    end

    it("registers an offense and does not fail if the sig is not the first expression on its line") do
      expect_offense(<<~RUBY)
        true; sig { void }
        # Comment
        ^^^^^^^^^ Extra empty line or comment detected
        def m; end
      RUBY

      expect_correction(<<~RUBY)
        # Comment
        true; sig { void }
        def m; end
      RUBY
    end

    it("registers an offense for empty line following multiple sigs") do
      expect_offense(<<~RUBY)
        sig { void }
        sig { params(foo: String).void }

        ^{} Extra empty line or comment detected
        def bar(foo); end
      RUBY

      expect_correction(<<~RUBY)
        sig { void }
        sig { params(foo: String).void }
        def bar(foo); end
      RUBY
    end

    it("registers an offense for empty line in between multiple sigs") do
      expect_offense(<<~RUBY)
        sig { void }

        ^{} Extra empty line or comment detected
        sig { params(foo: String).void }
        def bar(foo); end
      RUBY

      expect_correction(<<~RUBY)
        sig { void }
        sig { params(foo: String).void }
        def bar(foo); end
      RUBY
    end
  end

  it "registers no offense when there is only a sig" do
    expect_no_offenses(<<~RUBY)
      sig { void }
    RUBY
  end

  it "registers no offense when there is only a method definition" do
    expect_no_offenses(<<~RUBY)
      def foo; end
    RUBY
  end
end
