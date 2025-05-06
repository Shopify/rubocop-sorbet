# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class SignatureBuildOrderTest < ::Minitest::Test
          MSG = "Sorbet/SignatureBuildOrder: Sig builders must be invoked in the following order: type_parameters, params, void."

          def setup
            @cop = target_cop.new
          end

          def test_allows_the_correct_order
            assert_no_offenses(<<~RUBY)
              sig { abstract.params(x: Integer).returns(Integer) }

              sig { params(x: Integer).void }

              sig { abstract.void }

              sig { void.soft }

              sig { override.void.checked(false) }

              sig { overridable.void }
            RUBY
          end

          def test_allows_using_multiline_sigs
            assert_no_offenses(<<~RUBY)
              sig do
                abstract
                  .params(x: Integer)
                  .returns(Integer)
              end
            RUBY
          end

          def test_doesnt_break_on_incomplete_signatures
            assert_no_offenses(<<~RUBY)
              sig {}
            RUBY

            assert_no_offenses(<<~RUBY)
              sig { params(a: Integer) }
            RUBY

            assert_no_offenses(<<~RUBY)
              sig { abstract }
            RUBY

            assert_no_offenses(<<~RUBY)
              sig { params(a: Integer).v }
            RUBY
          end

          def test_enforces_orders_of_builder_calls
            assert_offense(<<~RUBY)
              sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            RUBY
          end

          def test_autocorrects_sigs_in_the_correct_order
            assert_offense(<<~RUBY)
              sig { void.type_parameters(:U).params(x: T.type_parameter(:U)) }
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            RUBY

            assert_correction(<<~RUBY)
              sig { type_parameters(:U).params(x: T.type_parameter(:U)).void }
            RUBY
          end

          def test_autocorrects_sigs_with_generic_types_properly
            assert_offense(<<~RUBY)
              sig { void.type_parameters(:U).params(x: T.type_parameter(:U), y: T::Hash[String, Integer]) }
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            RUBY

            assert_correction(<<~RUBY)
              sig { type_parameters(:U).params(x: T.type_parameter(:U), y: T::Hash[String, Integer]).void }
            RUBY
          end

          def test_autocorrects_sigs_even_with_many_unknown_methods
            assert_offense(<<~RUBY)
              sig { void.foo.type_parameters(:U).bar.params(x: T.type_parameter(:U), y: T::Hash[String, Integer]).baz }
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet/SignatureBuildOrder: Sig builders must be invoked in the following order: type_parameters, foo, params, bar, void, baz.
            RUBY

            assert_correction(<<~RUBY)
              sig { type_parameters(:U).foo.params(x: T.type_parameter(:U), y: T::Hash[String, Integer]).bar.void.baz }
            RUBY
          end

          def test_ignores_unknown_methods_while_sorting_the_remainder_of_the_chain
            @cop = target_cop.new(cop_config({
              "Order" => [
                "returns",
                "override",
              ],
            }))

            assert_offense(<<~RUBY)
              sig { override.params(x: Integer).returns(Integer) }
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: returns, params, override.
            RUBY

            assert_correction(<<~RUBY)
              sig { returns(Integer).params(x: Integer).override }
            RUBY

            # Doesn't actually care about where params appears; only cares about relative ordering of returns and override.
            assert_offense(<<~RUBY)
              sig { override.returns(Integer).params(x: Integer) }
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: returns, override, params.
            RUBY

            assert_correction(<<~RUBY)
              sig { returns(Integer).override.params(x: Integer) }
            RUBY

            assert_offense(<<~RUBY)
              sig { params(x: Integer).override.returns(Integer) }
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: params, returns, override.
            RUBY

            assert_correction(<<~RUBY)
              sig { params(x: Integer).returns(Integer).override }
            RUBY
          end

          def test_allows_customizing_the_order
            @cop = target_cop.new(cop_config({
              "Order" => [
                "returns",
                "override",
              ],
            }))

            assert_offense(<<~RUBY)
              sig { override.returns(Integer) }
                    ^^^^^^^^^^^^^^^^^^^^^^^^^ Sig builders must be invoked in the following order: returns, override.
            RUBY

            assert_correction(<<~RUBY)
              sig { returns(Integer).override }
            RUBY
          end

          private

          def target_cop
            SignatureBuildOrder
          end
        end
      end
    end
  end
end
