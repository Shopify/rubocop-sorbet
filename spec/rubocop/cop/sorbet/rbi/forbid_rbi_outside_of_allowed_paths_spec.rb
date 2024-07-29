# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidRBIOutsideOfAllowedPaths, :config) do
  describe "with default configuration" do
    context "with an .rbi file outside of AllowedPaths" do
      it "makes an offense if an RBI file is outside of sorbet/rbi/**" do
        expect_offense(<<~RUBY, "some/dir/file.rbi")
          print 1
          ^{} RBI file path should match one of: rbi/**, sorbet/rbi/**
        RUBY
      end

      it "registers an offense when the file is empty" do
        expect_offense(<<~RUBY, "some/dir/file.rbi")
          ^{} RBI file path should match one of: rbi/**, sorbet/rbi/**
        RUBY
      end
    end

    context "with an .rbi file inside of rbi/**" do
      it "makes no offense if an RBI file is inside the rbi/** directory" do
        expect_no_offenses(<<~RUBY, "rbi/some/dir/file.rbi")
          print 1
        RUBY
      end
    end

    context "with an .rbi file inside of sorbet/rbi/**" do
      it "makes no offense if an RBI file is inside the sorbet/rbi/** directory" do
        expect_no_offenses(<<~RUBY, "sorbet/rbi/some/dir/file.rbi")
          print 1
        RUBY
      end
    end

    context "with a the absolute path to the file" do
      it "makes no offense if an RBI file is inside the sorbet/rbi/** directory" do
        expect_no_offenses(<<~RUBY, "#{Dir.pwd}/sorbet/rbi/some/dir/file.rbi")
          print 1
        RUBY
      end
    end
  end

  describe "with custom configuration and one allowed path" do
    let(:cop_config) do
      {
        "Enabled" => true,
        "AllowedPaths" => ["some/allowed/**"],
      }
    end

    context "with an .rbi file outside of the allowed path" do
      it "makes an offense if an RBI file is outside of the allowed path" do
        expect_offense(<<~RUBY, "some/forbidden/directory/file.rbi")
          print 1
          ^{} RBI file path should match one of: some/allowed/**
        RUBY
      end
    end

    context "with an .rbi file inside of allowed path" do
      it "makes no offense if an RBI file is inside an allowed path" do
        expect_no_offenses(<<~RUBY, "some/allowed/directory/file.rbi")
          print 1
        RUBY
      end
    end

    context "with a the absolute path to the file" do
      it "makes no offense if an RBI file is inside the sorbet/rbi/** directory" do
        expect_no_offenses(<<~RUBY, "#{Dir.pwd}/some/allowed/directory/file.rbi")
          print 1
        RUBY
      end
    end
  end

  describe "with custom configuration and multiple allowed paths" do
    let(:cop_config) do
      {
        "Enabled" => true,
        "AllowedPaths" => ["some/allowed/**", "hello/other/allowed/**"],
      }
    end

    context "with an .rbi file inside of one of the allowed paths" do
      it "makes no offense if an RBI file is inside one of the allowed paths" do
        expect_no_offenses(<<~RUBY, "hello/other/allowed/file.rbi")
          print 1
        RUBY
      end
    end

    context "with an .rbi file not in any of the allowed paths" do
      it "makes an offense if an RBI file is outside of the allowed path" do
        expect_offense(<<~RUBY, "some/forbidden/directory/file.rbi")
          print 1
          ^{} RBI file path should match one of: some/allowed/**, hello/other/allowed/**
        RUBY
      end
    end
  end

  describe "with broken configuration" do
    context "with an empty AllowedPaths array" do
      let(:cop_config) do
        {
          "Enabled" => true,
          "AllowedPaths" => [],
        }
      end

      it "makes an offense if AllowedPaths is set to an empty list" do
        expect_offense(<<~RUBY, "sorbet/rbi/file.rbi")
          print 1
          ^{} AllowedPaths cannot be empty
        RUBY
      end
    end

    context "with an nil AllowedPaths list" do
      let(:cop_config) do
        {
          "Enabled" => true,
          "AllowedPaths" => nil,
        }
      end

      it "makes an offense if AllowedPaths is set to nil" do
        expect_offense(<<~RUBY, "some/directory/file.rbi")
          print 1
          ^{} AllowedPaths expects an array
        RUBY
      end
    end

    context "with an AllowedPaths list containing only nil" do
      let(:cop_config) do
        {
          "Enabled" => true,
          "AllowedPaths" => [nil],
        }
      end

      it "makes an offense if AllowedPaths is a list containing only nil" do
        expect_offense(<<~RUBY, "some/directory/file.rbi")
          print 1
          ^{} AllowedPaths cannot be empty
        RUBY
      end
    end

    context "with a bad value for AllowedPaths" do
      let(:cop_config) do
        {
          "Enabled" => true,
          "AllowedPaths" => "sorbet/rbi/**",
        }
      end

      it "makes an offense if AllowedPaths is not an array" do
        expect_offense(<<~RUBY, "some/directory/file.rbi")
          print 1
          ^{} AllowedPaths expects an array
        RUBY
      end
    end
  end
end
