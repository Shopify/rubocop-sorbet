# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidRBIOutsideOfAllowedPaths, :config) do
  describe "with default configuration" do
    it "registers an offense if an RBI file is outside AllowedPaths" do
      expect_offense(<<~RUBY, filename: "some/dir/file.rbi")
        # ...
        ^ RBI file path should match one of: rbi/**, sorbet/rbi/**
      RUBY
    end

    it "registers no offenses if an RBI file is in sorbet/rbi" do
      expect_no_offenses(<<~RUBY, filename: "sorbet/rbi/some/dir/file.rbi")
        # ...
      RUBY
    end

    it "registers no offenses if an RBI file is in rbi/" do
      expect_no_offenses(<<~RUBY, filename: "rbi/some/dir/file.rbi")
        # ...
      RUBY
    end

    it "registers no offense if an allowed RBI file's path is absolute" do
      expect_no_offenses(<<~RUBY, filename: "#{Dir.pwd}/sorbet/rbi/some/dir/file.rbi")
        # ...
      RUBY
    end
  end

  describe "with custom configuration and one allowed path" do
    let(:cop_config) do
      {
        "AllowedPaths" => ["some/allowed/**"],
      }
    end

    it "registers an offense if an RBI file is outside of the allowed path" do
      expect_offense(<<~RUBY, filename: "some/forbidden/directory/file.rbi")
        # ...
        ^ RBI file path should match one of: some/allowed/**
      RUBY
    end

    it "registers no offenses if an RBI file is inside the allowed path" do
      expect_no_offenses(<<~RUBY, filename: "some/allowed/directory/file.rbi")
        # ...
      RUBY
    end

    it "registers no offense if an allowed RBI file's path is absolute" do
      expect_no_offenses(<<~RUBY, filename: "#{Dir.pwd}/some/allowed/directory/file.rbi")
        # ...
      RUBY
    end
  end

  describe "with custom configuration and multiple allowed paths" do
    let(:cop_config) do
      {
        "AllowedPaths" => ["some/allowed/**", "hello/other/allowed/**"],
      }
    end

    it "registers no offense if an RBI file is inside one of the allowed paths" do
      expect_no_offenses(<<~RUBY, filename: "hello/other/allowed/file.rbi")
        # ...
      RUBY
    end

    it "registers an offense if an RBI file is outside of the allowed paths" do
      expect_offense(<<~RUBY, filename: "some/forbidden/directory/file.rbi")
        # ...
        ^ RBI file path should match one of: some/allowed/**, hello/other/allowed/**
      RUBY
    end
  end

  describe "with broken configuration" do
    context "with an empty AllowedPaths array" do
      let(:cop_config) do
        {
          "AllowedPaths" => [],
        }
      end

      it "registers an offense regardless of the file path" do
        expect_offense(<<~RUBY, filename: "sorbet/rbi/file.rbi")
          # ...
          ^ AllowedPaths cannot be empty
        RUBY
      end
    end

    context "with a nil AllowedPaths list" do
      let(:cop_config) do
        {
          "AllowedPaths" => nil,
        }
      end

      it "registers an offense regardless of the file path" do
        expect_offense(<<~RUBY, filename: "sorbet/rbi/file.rbi")
          # ...
          ^ AllowedPaths expects an array
        RUBY
      end
    end

    context "with an AllowedPaths list containing only nil" do
      let(:cop_config) do
        {
          "AllowedPaths" => [nil],
        }
      end

      it "registers an offense regardless of the file path" do
        expect_offense(<<~RUBY, filename: "sorbet/rbi/file.rbi")
          # ...
          ^ AllowedPaths cannot be empty
        RUBY
      end
    end

    context "with a bad value for AllowedPaths" do
      let(:cop_config) do
        {
          "AllowedPaths" => "sorbet/rbi/**",
        }
      end

      it "registers an offense regardless of the file path" do
        expect_offense(<<~RUBY, filename: "sorbet/rbi/file.rbi")
          # ...
          ^ AllowedPaths expects an array
        RUBY
      end
    end
  end
end
