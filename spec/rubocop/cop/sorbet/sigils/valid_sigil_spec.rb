# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ValidSigil, :config) do
  shared_examples_for "no offense for missing sigils by default" do
    it("does not require a sigil by default") do
      expect_no_offenses(<<~RUBY)
        # frozen_string_literal: true
        class Foo; end
      RUBY
    end

    it("does not make offense if there is a valid sigil") do
      # If we are testing exact strictness, we need an exact match
      # to make it a valid sigil.
      # In all other cases, we can get away with "strong"
      strictness = cop_config["ExactStrictness"] || "strong"

      expect_no_offenses(<<~RUBY)
        # frozen_string_literal: true
        # typed: #{strictness}
        class Foo; end
      RUBY
    end
  end

  shared_examples_for "offense for an invalid sigil" do
    it "enforces that the Sorbet sigil must not be empty" do
      expect_offense(<<~RUBY)
        # Hello world!
        # typed:
        ^^^^^^^^ Sorbet sigil should not be empty.
        class Foo; end
      RUBY
    end

    it "enforces that the Sorbet sigil must be a valid strictness" do
      expect_offense(<<~RUBY)
        # Hello world!
        # typed: foobar
        ^^^^^^^^^^^^^^^ Invalid Sorbet sigil `foobar`.
        class Foo; end
      RUBY
    end 

    it "enforces whitespase surrounding valid strictness levels" do
      expect_offense(<<~RUBY)
        # Hello world!
        # typed: true# rubocop:todo Sorbet/StrictSigil
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Invalid Sorbet sigil `true#`.
        class Foo; end
      RUBY
    end
  end

  shared_examples_for "no autocorrect on files with sigil" do
    it("does not change files with a sigil") do
      expect(
        autocorrect_source(<<~RUBY),
          # frozen_string_literal: true
          # typed: strict
          class Foo; end
        RUBY
      )
        .to(eq(<<~RUBY))
          # frozen_string_literal: true
          # typed: strict
          class Foo; end
        RUBY
    end

    it("does not change files with an invalid sigil") do
      expect(
        autocorrect_source(<<~RUBY),
          # frozen_string_literal: true
          # typed: no
          class Foo; end
        RUBY
      )
        .to(eq(<<~RUBY))
          # frozen_string_literal: true
          # typed: no
          class Foo; end
        RUBY
    end
  end

  describe("RequireSigilOnAllFiles: false") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "RequireSigilOnAllFiles" => false,
      }
    end
    it_should_behave_like "no offense for missing sigils by default"
    it_should_behave_like "offense for an invalid sigil"
    it_should_behave_like "no autocorrect on files with sigil"
  end

  describe("RequireSigilOnAllFiles: true") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "RequireSigilOnAllFiles" => true,
      }
    end
    it_should_behave_like "offense for an invalid sigil"

    it "enforces that the Sorbet sigil must exist" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: false` to start (you can also use `rubocop -a` to automatically add this).
        class Foo; end
      RUBY
    end

    it "enforces that the sigil must be at the beginning of the file" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: false` to start (you can also use `rubocop -a` to automatically add this).
        SOMETHING = <<~FOO
          # typed: true
        FOO
      RUBY
    end

    it "allows Sorbet sigil" do
      expect_no_offenses(<<~RUBY)
        # typed: true
        class Foo; end
      RUBY
    end

    it "allows empty spaces at the beginning of the file" do
      expect_no_offenses(<<~RUBY)

        # typed: true
        class Foo; end
      RUBY
    end

    describe("autocorrect") do
      it_should_behave_like "no autocorrect on files with sigil"

      it("autocorrects by adding typed: false to file without sigil") do
        expect(
          autocorrect_source(<<~RUBY),
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: false
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end

  describe("SuggestedStrictness: true") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "RequireSigilOnAllFiles" => true,
        "SuggestedStrictness" => true,
      }
    end
    it_should_behave_like "offense for an invalid sigil"

    it "suggest the default strictness if the sigil is missing" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: true` to start (you can also use `rubocop -a` to automatically add this).
        class Foo; end
      RUBY
    end

    describe("autocorrect") do
      it_should_behave_like "no autocorrect on files with sigil"

      it("autocorrects by adding typed: true to file without sigil") do
        expect(
          autocorrect_source(<<~RUBY),
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: true
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end

  describe("SuggestedStrictness: strict") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "RequireSigilOnAllFiles" => true,
        "SuggestedStrictness" => "strict",
      }
    end
    it_should_behave_like "offense for an invalid sigil"

    it "suggest the default strictness if the sigil is missing" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: strict` to start (you can also use `rubocop -a` to automatically add this).
        class Foo; end
      RUBY
    end

    describe("autocorrect") do
      it_should_behave_like "no autocorrect on files with sigil"

      it("autocorrects by adding typed: strict to file without sigil") do
        expect(
          autocorrect_source(<<~RUBY),
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: strict
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end

  describe("MinimumStrictness: true") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "MinimumStrictness" => true,
      }
    end
    it_should_behave_like "no offense for missing sigils by default"
    it_should_behave_like "offense for an invalid sigil"

    it "makes offense if the strictness is below the minimum" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # typed: false
        ^^^^^^^^^^^^^^ Sorbet sigil should be at least `true` got `false`.
        class Foo; end
      RUBY
    end
  end

  describe("ExactStrictness: true") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "ExactStrictness" => "true",
      }
    end
    it_should_behave_like "no offense for missing sigils by default"
    it_should_behave_like "offense for an invalid sigil"

    it "makes offense if the strictness is below the expected strictness" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # typed: false
        ^^^^^^^^^^^^^^ Sorbet sigil should be `true` got `false`.
        class Foo; end
      RUBY
    end

    it "makes offense if the strictness is above the expected strictness" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # typed: strict
        ^^^^^^^^^^^^^^^ Sorbet sigil should be `true` got `strict`.
        class Foo; end
      RUBY
    end

    describe("RequireSigilOnAllFiles: true") do
      let(:cop_config) do
        {
          "Enabled" => true,
          "RequireSigilOnAllFiles" => true,
          "ExactStrictness" => "true",
          "MinimumStrictness" => "false",
          "SuggestedStrictness" => "strict",
        }
      end
      it_should_behave_like "offense for an invalid sigil"

      it "suggest the expected strictness if the sigil is missing" do
        expect_offense(<<~RUBY)
          # frozen_string_literal: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: true` to start (you can also use `rubocop -a` to automatically add this).
          class Foo; end
        RUBY
      end
    end
  end

  describe("MinimumStrictness: strict") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "MinimumStrictness" => "strict",
      }
    end
    it_should_behave_like "no offense for missing sigils by default"
    it_should_behave_like "offense for an invalid sigil"

    it "makes offense if the strictness is below the minimum" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # typed: true
        ^^^^^^^^^^^^^ Sorbet sigil should be at least `strict` got `true`.
        class Foo; end
      RUBY
    end
  end

  describe("ExactStrictness: strict") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "ExactStrictness" => "strict",
      }
    end
    it_should_behave_like "no offense for missing sigils by default"
    it_should_behave_like "offense for an invalid sigil"

    it "makes offense if the strictness is below the expected strictness" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # typed: true
        ^^^^^^^^^^^^^ Sorbet sigil should be `strict` got `true`.
        class Foo; end
      RUBY
    end

    it "makes offense if the strictness is above the expected strictness" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        # typed: strong
        ^^^^^^^^^^^^^^^ Sorbet sigil should be `strict` got `strong`.
        class Foo; end
      RUBY
    end
  end

  describe("SuggestedStrictness: true, MinimumStrictness: false") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "RequireSigilOnAllFiles" => true,
        "MinimumStrictness" => "false",
        "SuggestedStrictness" => "true",
      }
    end
    it_should_behave_like "offense for an invalid sigil"

    it "suggest the default strictness if the sigil is missing" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: true` to start (you can also use `rubocop -a` to automatically add this).
        class Foo; end
      RUBY
    end

    describe("autocorrect") do
      it_should_behave_like "no autocorrect on files with sigil"

      it("autocorrects by adding typed: true to file without sigil") do
        expect(
          autocorrect_source(<<~RUBY),
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: true
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end

  describe("SuggestedStrictness: false, MinimumStrictness: ignore") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "RequireSigilOnAllFiles" => true,
        "MinimumStrictness" => "ignore",
        "SuggestedStrictness" => "false",
      }
    end
    it_should_behave_like "offense for an invalid sigil"

    it "suggest the default strictness if the sigil is missing" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: false` to start (you can also use `rubocop -a` to automatically add this).
        class Foo; end
      RUBY
    end

    describe("autocorrect") do
      it_should_behave_like "no autocorrect on files with sigil"

      it("autocorrects by adding typed: false to file without sigil") do
        expect(
          autocorrect_source(<<~RUBY),
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: false
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end

  describe("SuggestedStrictness: invalid_value, MinimumStrictness: true") do
    let(:cop_config) do
      {
        "Enabled" => true,
        "RequireSigilOnAllFiles" => true,
        "MinimumStrictness" => "true",
        "SuggestedStrictness" => "invalid_value",
      }
    end
    it_should_behave_like "offense for an invalid sigil"

    it "suggest the default strictness if the sigil is missing" do
      expect_offense(<<~RUBY)
        # frozen_string_literal: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ No Sorbet sigil found in file. Try a `typed: true` to start (you can also use `rubocop -a` to automatically add this).
        class Foo; end
      RUBY
    end

    describe("autocorrect") do
      it_should_behave_like "no autocorrect on files with sigil"

      it("autocorrects by adding typed: true to file without sigil") do
        expect(
          autocorrect_source(<<~RUBY),
            # frozen_string_literal: true
            class Foo; end
          RUBY
        )
          .to(eq(<<~RUBY))
            # typed: true
            # frozen_string_literal: true
            class Foo; end
          RUBY
      end
    end
  end
end
