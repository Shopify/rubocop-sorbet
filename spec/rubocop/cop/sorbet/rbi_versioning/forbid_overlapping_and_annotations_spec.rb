# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::ForbidOverlappingAndAnnotations, :config) do
  it "does not register an offense when comment is not a version annotation" do
    expect_no_offenses(<<~RUBY)
      # a random comment
    RUBY
  end

  it "does not register an offense when versions do not overlap" do
    expect_no_offenses(<<~RUBY)
      # @version < 1.0, >= 2.0
    RUBY
  end

  it "registers an offense when one version is contained within a range" do
    expect_offense(<<~RUBY)
      # @version < 1.0, = 0.4.0
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Some message here
    RUBY
  end

  it "registers an offense when one version is contained within one of a few ranges" do
    expect_offense(<<~RUBY)
      # @version > 5.0, < 1.0, = 0.4
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Some message here
    RUBY
  end

  it "does not register an offense when one version partially overlaps with another" do
    expect_no_offenses(<<~RUBY)
      # @version > 5.0, < 7.0
    RUBY
  end

  it "registers an offense when twiddle-waka operator is used" do
    expect_offense(<<~RUBY)
      # @version ~> 3.6, = 3.6.8
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Some message here
    RUBY
  end

  it "registers an offense when not-equal operator is used" do
    expect_offense(<<~RUBY)
      # @version != 4.0, <= 3.8
      ^^^^^^^^^^^^^^^^^^^^^^^^^ Some message here
    RUBY
  end
end
