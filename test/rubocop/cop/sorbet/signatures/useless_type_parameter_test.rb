# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class UselessTypeParameterTest < ::Minitest::Test
          def setup
            @cop = target_cop.new(cop_config)
          end

          def target_cop
            UselessTypeParameter
          end

          def test_removes_unreferenced_sorbet_type_parameter
            assert_offense(<<~RUBY)
              sig { type_parameters(:Used, :Unused).params(value: T.type_parameter(:Used)).returns(T.type_parameter(:Used)) }
                                           ^^^^^^^ Type parameter `Unused` must be referenced at least twice.
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              sig { type_parameters(:Used).params(value: T.type_parameter(:Used)).returns(T.type_parameter(:Used)) }
              def foo(value); end
            RUBY
          end

          def test_replaces_single_sorbet_input_use_with_untyped
            assert_offense(<<~RUBY)
              sig { type_parameters(:Item).params(value: T.type_parameter(:Item)).void }
                                    ^^^^^ Type parameter `Item` must be referenced at least twice.
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              sig { params(value: T.untyped).void }
              def foo(value); end
            RUBY
          end

          def test_reindents_multiline_builder_promoted_by_correction
            assert_offense(<<~RUBY)
              sig do
                type_parameters(:Item).
                                ^^^^^ Type parameter `Item` must be referenced at least twice.
                  params(
                    value: T.type_parameter(:Item),
                  )
              end
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              sig do
                params(
                  value: T.untyped,
                )
              end
              def foo(value); end
            RUBY
          end

          def test_reindents_leading_dot_builder_promoted_by_correction
            assert_offense(<<~RUBY)
              sig do
                type_parameters(:Item)
                                ^^^^^ Type parameter `Item` must be referenced at least twice.
                  .params(
                    value: T.type_parameter(:Item),
                  )
              end
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              sig do
                params(
                  value: T.untyped,
                )
              end
              def foo(value); end
            RUBY
          end

          def test_replaces_single_sorbet_output_use_with_untyped
            assert_offense(<<~RUBY)
              sig { type_parameters(:Item).returns(T.type_parameter(:Item)) }
                                    ^^^^^ Type parameter `Item` must be referenced at least twice.
              def foo; end
            RUBY

            assert_correction(<<~RUBY)
              sig { returns(T.untyped) }
              def foo; end
            RUBY
          end

          def test_replaces_single_sorbet_block_input_use_with_untyped
            assert_offense(<<~RUBY)
              sig { type_parameters(:Item).params(block: T.proc.params(value: T.type_parameter(:Item)).void).void }
                                    ^^^^^ Type parameter `Item` must be referenced at least twice.
              def foo(&block); end
            RUBY

            assert_correction(<<~RUBY)
              sig { params(block: T.proc.params(value: T.untyped).void).void }
              def foo(&block); end
            RUBY
          end

          def test_removes_single_sorbet_use_from_intersection
            assert_offense(<<~RUBY)
              sig { type_parameters(:T).params(value: T.all(T.type_parameter(:T), Foo)).void }
                                    ^^ Type parameter `T` must be referenced at least twice.
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              sig { params(value: Foo).void }
              def foo(value); end
            RUBY
          end

          def test_removes_single_sorbet_use_from_union
            assert_offense(<<~RUBY)
              sig { type_parameters(:T).params(value: T.any(T.type_parameter(:T), Foo)).void }
                                    ^^ Type parameter `T` must be referenced at least twice.
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              sig { params(value: Foo).void }
              def foo(value); end
            RUBY
          end

          def test_accepts_nested_single_sorbet_use_without_safe_rewrite
            assert_no_offenses(<<~RUBY)
              sig { type_parameters(:T).params(values: T::Array[T.type_parameter(:T)]).void }
              def foo(values); end
            RUBY
          end

          def test_accepts_sorbet_type_parameters_that_connect_positions
            assert_no_offenses(<<~RUBY)
              sig do
                type_parameters(:Input, :Output)
                  .params(
                    input: T.type_parameter(:Input),
                    transform: T.proc.params(value: T.type_parameter(:Input)).returns(T.type_parameter(:Output)),
                  )
                  .returns(T.type_parameter(:Output))
              end
              def foo(input, transform); end
            RUBY
          end

          def test_accepts_parenthesized_type_parameter_that_connects_positions
            assert_no_offenses(<<~RUBY)
              sig do
                type_parameters(:T)
                  .params(block: T.proc.returns(T.type_parameter((:T))))
                  .returns(T.type_parameter(:T))
              end
              def foo(&block); end
            RUBY
          end

          def test_removes_sorbet_builder_with_multiple_unreferenced_type_parameters
            assert_offense(<<~RUBY)
              sig { type_parameters(:First, :Second).void }
                                    ^^^^^^ Type parameter `First` must be referenced at least twice.
                                            ^^^^^^^ Type parameter `Second` must be referenced at least twice.
              def foo; end
            RUBY

            assert_correction(<<~RUBY)
              sig { void }
              def foo; end
            RUBY
          end

          def test_removes_unreferenced_rbs_type_parameter
            assert_offense(<<~RUBY)
              #: [Used, Unused] (Used) -> Used
                        ^^^^^^ Type parameter `Unused` must be referenced at least twice.
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              #: [Used] (Used) -> Used
              def foo(value); end
            RUBY
          end

          def test_replaces_single_rbs_input_use_with_untyped
            assert_offense(<<~RUBY)
              #: [T] (T) -> void
                  ^ Type parameter `T` must be referenced at least twice.
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              #: (untyped) -> void
              def foo(value); end
            RUBY
          end

          def test_replaces_single_rbs_output_use_with_untyped
            assert_offense(<<~RUBY)
              #: [T] () -> T
                  ^ Type parameter `T` must be referenced at least twice.
              def foo; end
            RUBY

            assert_correction(<<~RUBY)
              #: () -> untyped
              def foo; end
            RUBY
          end

          def test_replaces_single_rbs_block_input_use_with_untyped
            assert_offense(<<~RUBY)
              #: [T] () { (T) -> void } -> void
                  ^ Type parameter `T` must be referenced at least twice.
              def foo(&block); end
            RUBY

            assert_correction(<<~RUBY)
              #: () { (untyped) -> void } -> void
              def foo(&block); end
            RUBY
          end

          def test_removes_single_rbs_use_from_intersection
            assert_offense(<<~RUBY)
              #: [T] (T & Foo) -> void
                  ^ Type parameter `T` must be referenced at least twice.
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              #: (Foo) -> void
              def foo(value); end
            RUBY
          end

          def test_replaces_intersection_of_only_useless_rbs_parameters_with_untyped
            assert_offense(<<~RUBY)
              #: [A, B] (A & B) -> void
                  ^ Type parameter `A` must be referenced at least twice.
                     ^ Type parameter `B` must be referenced at least twice.
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              #: (untyped) -> void
              def foo(value); end
            RUBY
          end

          def test_accepts_rbs_type_parameters_that_connect_positions
            assert_no_offenses(<<~RUBY)
              #: [T] (T) -> T
              def identity(value); end

              #: [T] (T, T) -> void
              def compare(left, right); end

              #: [T] (T) { (T) -> void } -> void
              def consume(value, &block); end
            RUBY
          end

          def test_accepts_constrained_rbs_type_parameter_with_one_use
            assert_no_offenses(<<~RUBY)
              #: [T < Numeric] (T) -> void
              def consume(value); end
            RUBY
          end

          def test_checks_each_rbs_overload
            assert_offense(<<~RUBY)
              #: [Used] (Used) -> Used
              #: [Unused] () -> void
                  ^^^^^^ Type parameter `Unused` must be referenced at least twice.
              def foo(value = nil); end
            RUBY

            assert_correction(<<~RUBY)
              #: [Used] (Used) -> Used
              #: () -> void
              def foo(value = nil); end
            RUBY
          end

          def test_corrects_multiline_rbs_type_parameter_list
            assert_offense(<<~RUBY)
              #: [
              #| Used,
              #| Unused
                 ^^^^^^ Type parameter `Unused` must be referenced at least twice.
              #| ] (Used) -> Used
              def foo(value); end
            RUBY

            assert_correction(<<~RUBY)
              #: [Used] (Used) -> Used
              def foo(value); end
            RUBY
          end

          def test_ignores_malformed_rbs_signature
            assert_no_offenses(<<~RUBY)
              #: [Unused] ( ->
              def foo; end
            RUBY
          end
        end
      end
    end
  end
end
