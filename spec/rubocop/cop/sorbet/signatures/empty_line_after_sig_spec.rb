# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::EmptyLineAfterSig, :config) do
  describe("no offenses") do
    it "makes no offense when signarure and method are next to eachother" do
      expect_no_offenses(<<~RUBY)
        sig { void }
        def foo; end
      RUBY
    end
  end
  describe("with offences") do
    it "makes offense there is a line between a method and a signature" do
      expect_offense(<<~RUBY)
        sig { void }

        ^{} Extra empty line or comment detected
        def foo; end
      RUBY
    end

    it "supports various method defs" do
      expect_offense(<<~RUBY)
        sig { void }

        ^{} Extra empty line or comment detected
        def self.foo; end

        sig { void }

        ^{} Extra empty line or comment detected
        attr_reader :bar
      RUBY
    end
  end
  describe("autocorrect") do
    it("removes the empty line for single-line sigs") do
      source = <<~RUBY
        module Example
          extend T::Sig

          sig { params(session: String).void }

          def initialize(session:)
            @session = session
          end
        end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          module Example
            extend T::Sig

            sig { params(session: String).void }
            def initialize(session:)
              @session = session
            end
          end
        RUBY
    end

    it("removes the empty line for multiline sigs with identation") do
      source = <<~RUBY
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
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
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

    it("moves comments above the sig") do
      source = <<~RUBY
        module Example
          extend T::Sig

          sig do
            params(
              session: String,
            ).void
          end
          # Session: string
          def initialize(
            session:
          )
            @session = session
          end
        end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
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
  end
end
