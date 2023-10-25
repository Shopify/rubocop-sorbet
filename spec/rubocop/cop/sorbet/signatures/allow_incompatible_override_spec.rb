# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::AllowIncompatibleOverride, :config) do
  let(:message) { RuboCop::Cop::Sorbet::AllowIncompatibleOverride::MSG }

  it("allows using override(allow_incompatible: true) outside of sig") do
    expect_no_offenses(<<~RUBY)
      class Foo
        override(allow_incompatible: true)
      end
    RUBY
  end

  it("disallows using override(allow_incompatible: true)") do
    expect_offense(<<~RUBY)
      class Foo
        sig(a: Integer).override(allow_incompatible: true).void
                                 ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it("disallows using override(allow_incompatible: true) with block syntax") do
    expect_offense(<<~RUBY)
      class Foo
        sig { override(allow_incompatible: true).void }
                       ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it("disallows using receiver and override(allow_incompatible: true) with block syntax") do
    expect_offense(<<~RUBY)
      class Foo
        sig { recv.override(allow_incompatible: true).void }
                            ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it("disallows using override(allow_incompatible: true) with block syntax and params") do
    expect_offense(<<~RUBY)
      class Foo
        sig { override(allow_incompatible: true).params(a: Integer).void }
                       ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it("disallows using override(allow_incompatible: true) even when other keywords are present") do
    expect_offense(<<~RUBY)
      class Foo
        sig(a: Integer).override(allow_incompatible: true, something: :unrelated).void
                                 ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it("disallows using override(allow_incompatible: true) even when the sig is out of order") do
    expect_offense(<<~RUBY)
      class Foo
        sig(a: Integer).void.override(allow_incompatible: true, something: :unrelated)
                                      ^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it("allows override without allow_incompatible") do
    expect_no_offenses(<<~RUBY)
      class Foo
        sig(a: Integer).override.void
      end
    RUBY
  end

  it("doesn't break on incomplete signatures") do
    expect_no_offenses(<<~RUBY)
      class Foo
        sig {  }
        def foo; end
      end
    RUBY
  end
end
