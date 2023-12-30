# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::VoidCheckedTests, :config) do
  def message
      "The return value in a `.void.checked(:tests)` makes test behavior " \
        "diffferent from non-test behavior. Either use " \
        "`.returns(T.anything).checked(:tests)` to keep checking in tests, " \
        "or `.void.checked(:never)` to leave the return completely untouched."
  end

  describe("offenses") do
    it("disallows using .void.checked(:tests)") do
      expect_offense(<<~RUBY)
        sig { void.checked(:tests) }
              ^^^^ #{message}
        def foo; end
      RUBY

      expect_correction(<<~RUBY)
        sig { returns(T.anything).checked(:tests) }
        def foo; end
      RUBY

      expect_offense(<<~RUBY)
        sig { void.params(x: Integer).override.checked(:tests) }
              ^^^^ #{message}
        def foo(x); end
      RUBY

      expect_correction(<<~RUBY)
        sig { returns(T.anything).params(x: Integer).override.checked(:tests) }
        def foo(x); end
      RUBY

      expect_offense(<<~RUBY)
        sig { params(x: Integer).void.checked(:tests) }
                                 ^^^^ #{message}
        def foo(x); end
      RUBY

      expect_correction(<<~RUBY)
        sig { params(x: Integer).returns(T.anything).checked(:tests) }
        def foo(x); end
      RUBY
    end

    it("allows using .returns(T.anything).checked(:tests)") do
      expect_no_offenses(<<~RUBY)
        sig { returns(T.anything).checked(:tests) }
        def foo; end
      RUBY

      expect_no_offenses(<<~RUBY)
        sig { returns(T.anything).params(x: Integer).override.checked(:tests) }
        def foo(x); end
      RUBY

      expect_no_offenses(<<~RUBY)
        sig { params(x: Integer).returns(T.anything).checked(:tests) }
        def foo(x); end
      RUBY
    end

    it("is not tripped up by the `.void` in `T.proc.void`") do
      expect_no_offenses(<<~RUBY)
        sig { params(blk: T.proc.void).returns(T.anything).checked(:tests) }
        def foo(&blk); end
      RUBY
    end
  end
end
