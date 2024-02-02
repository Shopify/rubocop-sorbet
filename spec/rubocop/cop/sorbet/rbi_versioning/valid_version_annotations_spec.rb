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
      ^^^^^^^^^^^^^^^^^ Invalid gem version(s) detected: = blah
    RUBY
  end

  it "registers an offense when one gem version out of the list is not formatted correctly" do
    expect_offense(<<~RUBY)
      # @version < 3.2, > 4, ~> five
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Invalid gem version(s) detected: ~> five
    RUBY
  end

  it "registers an offense when one gem version is not formatted correctly in an OR" do
    expect_offense(<<~RUBY)
      # @version < 3.2, > 4
      # @version ~> five
      ^^^^^^^^^^^^^^^^^^ Invalid gem version(s) detected: ~> five
    RUBY
  end

  it "registers an offense for multiple incorrectly formatted versions" do
    expect_offense(<<~RUBY)
      # @version < 3.2, ~> five, = blah
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Invalid gem version(s) detected: ~> five, = blah
    RUBY
  end
end
