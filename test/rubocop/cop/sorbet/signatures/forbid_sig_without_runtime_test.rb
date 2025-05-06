# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class ForbidSigWithoutRuntimeTest < ::Minitest::Test
          MSG = "Sorbet/ForbidSigWithoutRuntime: Do not use `T::Sig::WithoutRuntime.sig`."

          def setup
            @cop = ForbidSigWithoutRuntime.new
          end

          def test_allows_using_sig
            assert_no_offenses(<<~RUBY)
              sig { void }
              def foo; end
            RUBY
          end

          def test_allows_using_t_sig_sig
            assert_no_offenses(<<~RUBY)
              T::Sig.sig { void }
              def foo; end
            RUBY
          end

          def test_disallows_using_t_sig_without_runtime_sig_with_curly_braces
            assert_offense(<<~RUBY)
              T::Sig::WithoutRuntime.sig { void }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def foo; end
            RUBY

            assert_correction(<<~RUBY)
              sig { void }
              def foo; end
            RUBY
          end

          def test_disallows_using_t_sig_without_runtime_sig_with_do_end
            assert_offense(<<~RUBY)
              T::Sig::WithoutRuntime.sig do
              ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                void
              end
              def self.foo(x); end
            RUBY

            assert_correction(<<~RUBY)
              sig do
                void
              end
              def self.foo(x); end
            RUBY
          end

          def test_autocorrects_with_correct_parameters_and_block
            assert_offense(<<~RUBY)
              T::Sig::WithoutRuntime.sig(:final) do
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                params(
                  x: A,
                  y: B,
                ).returns(C)
              end
              def self.foo(x, y); end
            RUBY

            assert_correction(<<~RUBY)
              sig(:final) do
                params(
                  x: A,
                  y: B,
                ).returns(C)
              end
              def self.foo(x, y); end
            RUBY
          end

          def test_autocorrects_with_correct_parameters_and_block_in_multiline_sig
            assert_offense(<<~RUBY)
              T::
              ^^^ #{MSG}
                Sig::
                  WithoutRuntime
                    .sig(:final) do
                params(
                  x: A,
                  y: B,
                ).returns(C)
              end
              def self.foo(x, y); end
            RUBY

            assert_correction(<<~RUBY)
              sig(:final) do
                params(
                  x: A,
                  y: B,
                ).returns(C)
              end
              def self.foo(x, y); end
            RUBY
          end
        end
      end
    end
  end
end
