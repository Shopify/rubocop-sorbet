# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidRBIOutsideOfAllowedPaths, :config) do
  subject(:cop) { described_class.new(config) }

  let(:source) { "print 1" }
  let(:processed_source) { parse_source(source) }

  before do
    allow(processed_source.buffer).to(receive(:name).and_return(filename))
    _investigate(cop, processed_source)
  end

  describe "with default configuration" do
    context "with an .rbi file outside of sorbet/rbi/**" do
      let(:filename) { "some/dir/file.rbi" }

      it "makes an offense if an RBI file is outside of sorbet/rbi/**" do
        expect(cop.offenses.size).to(eq(1))
        expect(cop.messages).to(eq(["RBI file path should match one of: sorbet/rbi/**"]))
      end
    end

    context "with an .rbi file inside of sorbet/rbi/**" do
      let(:filename) { "sorbet/rbi/ome/dir/file.rbi" }

      it "makes no offense if an RBI file is inside the sorbet/rbi/** directory" do
        expect(cop.offenses.empty?).to(be(true))
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
      let(:filename) { "some/forbidden/directory/file.rbi" }

      it "makes an offense if an RBI file is outside of the allowed path" do
        expect(cop.offenses.size).to(eq(1))
        expect(cop.messages).to(eq(["RBI file path should match one of: some/allowed/**"]))
      end
    end

    context "with an .rbi file inside of allowed path" do
      let(:filename) { "some/allowed/directory/file.rbi" }

      it "makes no offense if an RBI file is inside an allowed path" do
        expect(cop.offenses.empty?).to(be(true))
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
      let(:filename) { "hello/other/allowed/file.rbi" }

      it "makes no offense if an RBI file is inside one of the allowed paths" do
        expect(cop.offenses.empty?).to(be(true))
      end
    end

    context "with an .rbi file not in any of the allowed paths" do
      let(:filename) { "some/forbidden/directory/file.rbi" }

      it "makes an offense if an RBI file is outside of the allowed path" do
        expect(cop.offenses.size).to(eq(1))
        expect(cop.messages).to(eq(["RBI file path should match one of: some/allowed/**, hello/other/allowed/**"]))
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

      let(:filename) { "sorbet/rbi/file.rbi" }
      it "makes an offense if AllowedPaths is set to an empty list" do
        expect(cop.offenses.size).to(eq(1))
        expect(cop.messages).to(eq(
          ["AllowedPaths cannot be empty"]
        ))
      end
    end

    context "with an nil AllowedPaths list" do
      let(:cop_config) do
        {
          "Enabled" => true,
          "AllowedPaths" => nil,
        }
      end

      let(:filename) { "some/directory/file.rbi" }

      it "makes an offense if AllowedPaths is set to nil" do
        expect(cop.offenses.size).to(eq(1))
        expect(cop.messages).to(eq(
          ["AllowedPaths expects an array"]
        ))
      end
    end

    context "with an AllowedPaths list containing only nil" do
      let(:cop_config) do
        {
          "Enabled" => true,
          "AllowedPaths" => [nil],
        }
      end

      let(:filename) { "some/directory/file.rbi" }

      it "makes an offense if AllowedPaths is a list containing only nil" do
        expect(cop.offenses.size).to(eq(1))
        expect(cop.messages).to(eq(
          ["AllowedPaths cannot be empty"]
        ))
      end
    end

    context "with a bad value for AllowedPaths" do
      let(:cop_config) do
        {
          "Enabled" => true,
          "AllowedPaths" => "sorbet/rbi/**",
        }
      end

      let(:filename) { "some/directory/file.rbi" }

      it "makes an offense if AllowedPaths is not an array" do
        expect(cop.offenses.size).to(eq(1))
        expect(cop.messages).to(eq(
          ["AllowedPaths expects an array"]
        ))
      end
    end
  end
end
