# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidRBIOutsideOfSorbetDir, :config) do
  subject(:cop) { described_class.new(config) }

  let(:source) { "print 1" }
  let(:processed_source) { parse_source(source) }

  before do
    allow(processed_source.buffer).to(receive(:name).and_return(filename))
    _investigate(cop, processed_source)
  end

  context "with an .rbi file outside of sorbet/" do
    let(:filename) { "some/dir/file.rbi" }

    it "makes offense if an RBI file is outside of the sorbet/ directory" do
      expect(cop.offenses.size).to(eq(1))
      expect(cop.messages).to(eq(["RBI files are only accepted in the sorbet/rbi/ directory."]))
    end
  end

  context "with an .rbi file inside of sorbet/" do
    let(:filename) { "sorbet/rbi/ome/dir/file.rbi" }

    it "makes no offense if an RBI file is inside the sorbet/ directory" do
      expect(cop.offenses.empty?).to(be(true))
    end
  end
end
