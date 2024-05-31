# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidNestedTMust, :config) do
  it "adds offense when there is one nested T.must" do
    expect_offense(<<~RUBY)
      T.must(T.must(A.b).c)
      ^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(A.b&.c)\n")
  end

  it "adds offense when there are consecutive calls after T.must and correction enforces safe-navigation" do
    expect_offense(<<~RUBY)
      T.must(T.must(b).c.d.e)
      ^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(b&.c&.d&.e)\n")
  end

  it "adds offense when there are interleaving calls after T.must and correction enforces safe-navigation" do
    expect_offense(<<~RUBY)
      T.must(T.must(b).c&.d.e&.f)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(b&.c&.d&.e&.f)\n")
  end

  it "adds offense when last call is safe-navigation and correction enforces safe-navigation" do
    expect_offense(<<~RUBY)
      T.must(T.must(b).c.d&.e.f&.g&.h)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(b&.c&.d&.e&.f&.g&.h)\n")
  end

  it "adds offense when safe-navigation applied to a method and correction enforces safe-navigation" do
    expect_offense(<<~RUBY)
      T.must(T.must(a).b&.c().d)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(a&.b&.c()&.d)\n")
  end

  it "adds offense when safe-navigation applied to a method with args and correction enforces safe-navigation" do
    expect_offense(<<~RUBY)
      T.must(T.must(a).b&.c('sleepy').d)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(a&.b&.c('sleepy')&.d)\n")
  end

  it "adds offense when there are two nested T.must" do
    expect_offense(<<~RUBY)
      T.must(T.must(T.must(A.b&.b).b).c)
             ^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(T.must(A.b&.b).b&.c)\n")
  end

  it "adds offense when there are two directly nested T.must" do
    expect_offense(<<~RUBY)
      T.must(T.must(T.must(a.b)).c)
             ^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(T.must(a.b).c)\n")
  end

  it "adds offense when there are three nested T.must" do
    expect_offense(<<~RUBY)
      T.must(T.must(T.must(T.must(A.b).b).b).c)
                    ^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(T.must(T.must(A.b).b).b&.c)\n")
  end

  it "adds offense when there are safe-navigation operators after the nested T.must" do
    expect_offense(<<~RUBY)
      T.must(T.must(A.b&.b).b&.b&.c)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(A.b&.b&.b&.b&.c)\n")
  end

  it "adds offense when there's a nested T.must with an index" do
    expect_offense(<<~RUBY)
      T.must(T.must(A.b)[:test])
      ^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(A.b&.[](:test))\n")
  end

  it "adds offense when there's a nested T.must with an index" do
    expect_offense(<<~RUBY)
      T.must(T.must(A.b)[:test].c.d('zzz'))
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(A.b&.[](:test)&.c&.d('zzz'))\n")
  end

  it "adds offense when first call after T.must is safe-navigation" do
    expect_offense(<<~RUBY)
      T.must(T.must(b)&.c)
      ^^^^^^^^^^^^^^^^^^^^ Please avoid nesting `T.must` calls, instead use a single `T.must` around a conditional-send (`&.`) chain
    RUBY

    expect_correction("T.must(b&.c)\n")
  end

  it "does not add offense when there is no nested T.must" do
    expect_no_offenses(<<~RUBY)
      T.must(A.b&.b&.b&.c)
    RUBY
  end

  it "does not add offense when the nested T.must is not a direct argument of the outer one" do
    expect_no_offenses(<<~RUBY)
      T.must(A.d(T.must(A.b&.c)))
    RUBY
  end

  it "does not add offense when indexing through a safe-navigation operator" do
    expect_no_offenses(<<~RUBY)
      T.must(A.b&.[](:test))
    RUBY
  end
end
