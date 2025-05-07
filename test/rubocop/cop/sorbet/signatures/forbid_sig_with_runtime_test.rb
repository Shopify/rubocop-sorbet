# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class ForbidSigWithRuntimeTest < ::Minitest::Test
          MSG = "Sorbet/ForbidSigWithRuntime: Do not use `T::Sig.sig`."

          def setup
            @cop = ForbidSigWithRuntime.new
          end

          def test_allows_using_t_sig_without_runtime_sig
            assert_no_offenses(<<~RUBY)
              T::Sig::WithoutRuntime.sig { void }
              def foo; end
            RUBY
          end

          def test_allows_using_sig
            assert_no_offenses(<<~RUBY)
              sig { void }
              def foo; end
            RUBY
          end

          def test_disallows_using_t_sig_sig_with_curly_braces
            assert_offense(<<~RUBY)
              T::Sig.sig { void }
              ^^^^^^^^^^^^^^^^^^^ #{MSG}
              def foo; end
            RUBY
          end

          def test_disallows_using_t_sig_sig_with_do_end
            assert_offense(<<~RUBY)
              T::Sig.sig do
              ^^^^^^^^^^^^^ #{MSG}
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
