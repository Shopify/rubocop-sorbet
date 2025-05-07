# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class ForbidSigTest < ::Minitest::Test
          MSG = "Sorbet/ForbidSig: Do not use `T::Sig`."

          def setup
            @cop = ForbidSig.new
          end

          def test_allows_using_t_sig_without_runtime_sig
            assert_no_offenses(<<~RUBY)
              T::Sig::WithoutRuntime.sig { void }
              def foo; end
            RUBY
          end

          def test_allows_using_t_sig_sig
            assert_no_offenses(<<~RUBY)
              T::Sig.sig { void }
              def foo; end
            RUBY
          end

          def test_disallows_using_sig_with_curly_braces
            assert_offense(<<~RUBY)
              sig { void }
              ^^^^^^^^^^^^ #{MSG}
              def foo; end
            RUBY
          end

          def test_disallows_using_sig_with_do_end
            assert_offense(<<~RUBY)
              sig do
              ^^^^^^ #{MSG}
                void
              end
              def self.foo(x); end
            RUBY
          end
        end
      end
    end
  end
end
