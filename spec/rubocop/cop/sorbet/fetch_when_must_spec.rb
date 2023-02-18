# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::FetchWhenMust, :config) do
  it "registers an offense when using `T.must(object[key])`" do
    expect_offense(<<~RUBY)
      T.must(object[key])
      ^^^^^^^^^^^^^^^^^^^ Use `object.fetch(key)` instead of `T.must(object[key])` when value must always be found, and receiver supports it.
    RUBY

    expect_correction(<<~RUBY)
      object.fetch(key)
    RUBY
  end

  it "does not register an offense when using `object[key]` without `T.must`" do
    expect_no_offenses(<<~RUBY)
      object[key]
    RUBY
  end

  it "does not register an offense when using `object[key]` without `T.must`" do
    expect_no_offenses(<<~RUBY)
      T.must(object.fetch(key))
    RUBY
  end

  it "does not register an offense when using `T.must(object[key1, key2])`" do
    expect_no_offenses(<<~RUBY)
      T.must(object[key1, key2])
    RUBY
  end

  context "when nested" do
    # Correcting nested nodes must be done in multiple passes: one per node.
    # Attempting to correct nested nodes in a single pass will result in clobbering.
    # Cop specs only perform the first correction pass, however the Corrector loops until no more corrections are made.
    # These specs ensure we don't cause the clobbering error.

    it "performs the first pass of two pass correction" do
      # Finds both offenses
      expect_offense(<<~RUBY)
        T.must(T.must(object[key1])[key2])
               ^^^^^^^^^^^^^^^^^^^^ Use `object.fetch(key1)` instead of `T.must(object[key1])` when value must always be found, and receiver supports it.
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `T.must(object[key1]).fetch(key2)` instead of `T.must(T.must(object[key1])[key2])` when value must always be found, and receiver supports it.
      RUBY

      # Only corrects outer node on this pass, avoiding clobbering error
      expect_correction(<<~RUBY)
        T.must(object[key1]).fetch(key2)
      RUBY
    end

    it "performs the second pass of two pass correction" do
      # Finds remaining offense
      expect_offense(<<~RUBY)
        T.must(object[key1]).fetch(key2)
        ^^^^^^^^^^^^^^^^^^^^ Use `object.fetch(key1)` instead of `T.must(object[key1])` when value must always be found, and receiver supports it.
      RUBY

      # Corrects inner node on this pass
      expect_correction(<<~RUBY)
        object.fetch(key1).fetch(key2)
      RUBY
    end
  end
end
