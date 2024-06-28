# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::ForbidFalsyAndAnnotaitons, :config) do
  it "does not register an offense when comment is not a version annotation" do
    expect_no_offenses(<<~RUBY)
      # a random comment
    RUBY
  end

  it "does not register an offense when comment contains a single version annotation" do
    expect_no_offenses(<<~RUBY)
      # @version != 1
    RUBY
  end

  it "does not register an offense when comment uses valid AND version annotations" do
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

  it "registers an offense for a falsy and annotation with two versions" do
    expect_offense(<<~RUBY)
      # @version < 1, > 3
      ^^^^^^^^^^^^^^^^^^^ Annotation excludes all versions
    RUBY
  end

  it "registers an offense for a falsy and annotation with three versions" do
    expect_offense(<<~RUBY)
      # @version <= 1, = 2, >= 3
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Annotation excludes all versions
    RUBY
  end

  it "registers an offense for a falsy annotation with all operators" do
    expect_offense(<<~RUBY)
      # @version = 1, != 1
      ^^^^^^^^^^^^^^^^^^^^ Annotation excludes all versions
      # @version ~> 3.4, > 4.0
      ^^^^^^^^^^^^^^^^^^^^^^^^ Annotation excludes all versions
      # @version < 1, = 1
      ^^^^^^^^^^^^^^^^^^^ Annotation excludes all versions
      # @version > 1, = 1
      ^^^^^^^^^^^^^^^^^^^ Annotation excludes all versions
      # @version <= 1, >= 2
      ^^^^^^^^^^^^^^^^^^^^^ Annotation excludes all versions
      # @version != 1, > 2
      ^^^^^^^^^^^^^^^^^^^^ Annotation excludes all versions
    RUBY
  end
end
