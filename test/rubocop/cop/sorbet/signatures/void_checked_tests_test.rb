# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class VoidCheckedTestsTest < ::Minitest::Test
          MSG = "Sorbet/VoidCheckedTests: Returning `.void` from a sig marked `.checked(:tests)` means that the " \
            "method will return a different value in non-test environments (possibly " \
            "with different truthiness). Either use `.returns(T.anything).checked(:tests)` " \
            "to keep checking in tests, or `.void.checked(:never)` to leave it untouched."

          def setup
            @cop = VoidCheckedTests.new
          end

          def test_disallows_using_void_checked_tests
            assert_offense(<<~RUBY)
              sig { void.checked(:tests) }
                    ^^^^ #{MSG}
              def foo; end
            RUBY

            assert_correction(<<~RUBY)
              sig { returns(T.anything).checked(:tests) }
              def foo; end
            RUBY

            assert_offense(<<~RUBY)
              sig { void.params(x: Integer).override.checked(:tests) }
                    ^^^^ #{MSG}
              def foo(x); end
            RUBY

            assert_correction(<<~RUBY)
              sig { returns(T.anything).params(x: Integer).override.checked(:tests) }
              def foo(x); end
            RUBY

            assert_offense(<<~RUBY)
              sig { params(x: Integer).void.checked(:tests) }
                                       ^^^^ #{MSG}
              def foo(x); end
            RUBY

            assert_correction(<<~RUBY)
              sig { params(x: Integer).returns(T.anything).checked(:tests) }
              def foo(x); end
            RUBY
          end

          def test_allows_using_returns_t_anything_checked_tests
            assert_no_offenses(<<~RUBY)
              sig { returns(T.anything).checked(:tests) }
              def foo; end
            RUBY

            assert_no_offenses(<<~RUBY)
              sig { returns(T.anything).params(x: Integer).override.checked(:tests) }
              def foo(x); end
            RUBY

            assert_no_offenses(<<~RUBY)
              sig { params(x: Integer).returns(T.anything).checked(:tests) }
              def foo(x); end
            RUBY
          end

          def test_is_not_tripped_up_by_the_void_in_t_proc_void
            assert_no_offenses(<<~RUBY)
              sig { params(blk: T.proc.void).returns(T.anything).checked(:tests) }
              def foo(&blk); end
            RUBY
          end

          def test_allows_void_in_initialize_methods
            assert_no_offenses(<<~RUBY)
              sig { void.checked(:tests) }
              def initialize; end
            RUBY
          end

          def test_allows_weird_nodes_between_sig_and_def
            # Happened in real test case in wild, where an initial version of this
            # cop raised an uncaught exception.
            assert_no_offenses(<<~RUBY)
              sig { void.checked(:tests) }
              X = 1
              def initialize; end
            RUBY
          end
        end
      end
    end
  end
end
