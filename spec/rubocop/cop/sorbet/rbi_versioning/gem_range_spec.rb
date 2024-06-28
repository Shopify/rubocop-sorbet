# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::GemRange, :config) do
  describe ".from_version_string" do
    it "represents an equals version" do
      range = RuboCop::Cop::Sorbet::GemRange.from_version_string("= 1.2.3")
      expect(range.begin).to(eq(Gem::Version.new("1.2.3")))
      expect(range.end).to(eq(Gem::Version.new("1.2.3")))
      expect(range.exclude_end?).to(be(false))
    end

    it "represents a less than version" do
      range = RuboCop::Cop::Sorbet::GemRange.from_version_string("< 1.2.3")
      expect(range.begin).to(be_nil)
      expect(range.end).to(eq(Gem::Version.new("1.2.3")))
      expect(range.exclude_end?).to(be(true))
    end

    it "represents a less than or equals version" do
      range = RuboCop::Cop::Sorbet::GemRange.from_version_string("<= 1.2.3")
      expect(range.begin).to(be_nil)
      expect(range.end).to(eq(Gem::Version.new("1.2.3")))
      expect(range.exclude_end?).to(be(false))
    end

    it "represents a twiddle-wakka version" do
      range = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.3")
      expect(range.begin).to(eq(Gem::Version.new("1.2.3")))
      expect(range.end).to(eq(Gem::Version.new("1.3.0")))
      expect(range.exclude_end?).to(be(true))
    end

    it "represents a greater than or equals version" do
      range = RuboCop::Cop::Sorbet::GemRange.from_version_string(">= 1.2.3")
      expect(range.begin).to(eq(Gem::Version.new("1.2.3")))
      expect(range.end).to(be_nil)
      expect(range.exclude_end?).to(be(false))
    end

    it "represents a greater than version" do
      range = RuboCop::Cop::Sorbet::GemRange.from_version_string("> 1.2.3")
      expect(range.begin).to(eq(Gem::Version.new("1.2.3.1")))
      expect(range.end).to(be_nil)
      expect(range.exclude_end?).to(be(false))
    end
  end

  describe "#overlap?" do
    describe "when both ranges have definite endpoints" do
      it "returns true if the first range includes the other's starting point" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.3")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.4")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns true if the first range includes the other's end point" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.4")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.3")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns true if the first range is a superset of the second" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.3")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.3.4")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns true if the first range is a subset of the second" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.3.4")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.3")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns false if the ranges do not overlap" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.3")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 2.3.4")

        expect(range_1.overlap?(range_2)).to(be(false))
      end
    end

    describe "when one range has an indefinite endpoint" do
      it "returns true when the first range includes the other's end point" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string(">= 1.2.3")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.1")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns true when the second range includes the first's end point" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.1")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string(">= 1.2.3")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns true when the first range entirely includes the second range" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string(">= 1.2.3")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("= 1.2.5")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns true when the second range entirely includes the first range" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("= 1.2.5")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string(">= 1.2.3")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns false when the ranges don't overlap" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string(">= 1.2.3")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("= 1.1.1")

        expect(range_1.overlap?(range_2)).to(be(false))
      end
    end

    describe "when one range has an indefinite start point" do
      it "returns true when the first range includes the other's start point" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("<= 1.2.3")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.1")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns true when the second range includes the first's start point" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("~> 1.2.1")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("<= 1.2.3")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns true when the first range entirely includes the second range" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("<= 1.2.3")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("= 1.2.2")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns true when the second range entirely includes the first range" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("= 1.2.2")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("<= 1.2.3")

        expect(range_1.overlap?(range_2)).to(be(true))
      end

      it "returns false when the ranges don't overlap" do
        range_1 = RuboCop::Cop::Sorbet::GemRange.from_version_string("<= 1.2.3")
        range_2 = RuboCop::Cop::Sorbet::GemRange.from_version_string("= 1.3.1")

        expect(range_1.overlap?(range_2)).to(be(false))
      end
    end
  end
end
