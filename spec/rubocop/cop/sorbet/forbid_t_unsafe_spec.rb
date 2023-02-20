# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidTUnsafe, :config) do
  it "adds offense when using T.unsafe" do
    expect_offense(<<~RUBY)
      T.unsafe(foo)
      ^^^^^^^^^^^^^ Do not use `T.unsafe`.
    RUBY
  end
end
