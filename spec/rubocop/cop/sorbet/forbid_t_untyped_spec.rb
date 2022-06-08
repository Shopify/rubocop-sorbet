# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidTUntyped, :config) do
  subject(:cop) { described_class.new(config) }

  it "adds offense when using T.untyped" do
    expect_offense(<<~RUBY)
      T.untyped
      ^^^^^^^^^ Do not use `T.untyped`.
    RUBY
  end
end
