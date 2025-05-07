# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class CheckedTrueInSignatureTest < ::Minitest::Test
          MSG = "Sorbet/CheckedTrueInSignature: Using `checked(true)` in a method signature definition is not allowed. " \
            "`checked(true)` is the default behavior for modules/classes with runtime checks enabled. " \
            "To enable typechecking at runtime for this module, regardless of global settings, " \
            "`include(WaffleCone::RuntimeChecks)` to this module and set other methods to `checked(false)`."

          def setup
            @cop = CheckedTrueInSignature.new
          end

          def test_disallows_using_sig_checked_true
            assert_offense(<<~RUBY)
              sig { params(a: Integer).void.checked(true) }
                                            ^^^^^^^^^^^^^ #{MSG}
              def foo(a); end
            RUBY
          end

          def test_allows_using_checked_false
            assert_no_offenses(<<~RUBY)
              sig { params(a: Integer).void.checked(false) }
              def foo(a); end
            RUBY
          end
        end
      end
    end
  end
end
