# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::ValidVersionAnnotations, :config) do
  it "does not register an offense when comment is not a version annotation" do
    expect_no_offenses(<<~RUBY)
      # a random comment
    RUBY
  end

  it "does not register an offense when comment is a valid version annotation" do
    expect_no_offenses(<<~RUBY)
      # @version = 1.3.4-prerelease
    RUBY
  end

  it "does not register an offense when comment uses AND version annotations" do
    expect_no_offenses(<<~RUBY)
      # @version > 1, < 3.5
    RUBY
  end

  it "does not register an offense when comment uses OR version annotations" do
    expect_no_offenses(<<~RUBY)
      # @version > 1.3.6
      # @version <= 4
    RUBY
  end

  it "registers an offense when gem version is not formatted correctly" do
    expect_offense(<<~RUBY)
      # @version = blah
                 ^^^^^^ #{RuboCop::Cop::Sorbet::ValidVersionAnnotations::MSG}
    RUBY
  end

  it "registers an offense when one gem version out of the list is not formatted correctly" do
    expect_offense(<<~RUBY)
      # @version < 3.2, > 4, ~> five
                             ^^^^^^^ #{RuboCop::Cop::Sorbet::ValidVersionAnnotations::MSG}
    RUBY
  end

  it "registers an offense when one gem version is not formatted correctly in an OR" do
    expect_offense(<<~RUBY)
      # @version < 3.2, > 4
      # @version ~> five
                 ^^^^^^^ #{RuboCop::Cop::Sorbet::ValidVersionAnnotations::MSG}
    RUBY
  end
end
