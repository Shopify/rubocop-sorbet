# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTCollectionInstantiationTest < ::Minitest::Test
        MSG = ForbidTCollectionInstantiation::MSG

        def setup
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))
        end

        def test_registers_offense_for_parameterized_collections
          assert_offense(<<~RUBY)
            T::Array[String].new
            ^^^^^^^^^^^^^^^^ #{MSG}
            T::Hash[Symbol, Integer].new
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            T::Set[String].new
            ^^^^^^^^^^^^^^ #{MSG}
            T::Range[Integer].new(1, 3)
            ^^^^^^^^^^^^^^^^^ #{MSG}
            T::Enumerable[String].new
            ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            T::Enumerator[String].new { |y| y << "item" }
            ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            T::Enumerator::Lazy[String].new(items) { |y, item| y << item }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            T::Enumerator::Chain[String].new(first, second)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            Array.new #: Array[String]
            Hash.new #: Hash[Symbol, Integer]
            Set.new #: Set[String]
            Range.new(1, 3) #: Range[Integer]
            Enumerable.new #: Enumerable[String]
            Enumerator.new { |y| y << "item" } #: Enumerator[String]
            Enumerator::Lazy.new(items) { |y, item| y << item } #: Enumerator::Lazy[String]
            Enumerator::Chain.new(first, second) #: Enumerator::Chain[String]
          RUBY
        end

        def test_registers_offense_without_type_arguments
          assert_offense(<<~RUBY)
            T::Array.new(2)
            ^^^^^^^^ #{MSG}
            T::Hash.new(0)
            ^^^^^^^ #{MSG}
            T::Set.new(items)
            ^^^^^^ #{MSG}
            T::Range.new(1, 3)
            ^^^^^^^^ #{MSG}
            T::Enumerable.new
            ^^^^^^^^^^^^^ #{MSG}
            T::Enumerator.new { |y| y << "item" }
            ^^^^^^^^^^^^^ #{MSG}
            T::Enumerator::Lazy.new(items) { |y, item| y << item }
            ^^^^^^^^^^^^^^^^^^^ #{MSG}
            T::Enumerator::Chain.new(first, second)
            ^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            Array.new(2)
            Hash.new(0)
            Set.new(items)
            Range.new(1, 3)
            Enumerable.new
            Enumerator.new { |y| y << "item" }
            Enumerator::Lazy.new(items) { |y, item| y << item }
            Enumerator::Chain.new(first, second)
          RUBY
        end

        def test_registers_offense_with_root_qualified_constants
          assert_offense(<<~RUBY)
            ::T::Set[String].new
            ^^^^^^^^^^^^^^^^ #{MSG}
            ::T::Enumerator::Chain[String].new(first, second)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            ::Set.new #: ::Set[String]
            ::Enumerator::Chain.new(first, second) #: ::Enumerator::Chain[String]
          RUBY
        end

        def test_registers_offense_with_safe_navigation
          assert_offense(<<~RUBY)
            T::Array[String]&.new
            ^^^^^^^^^^^^^^^^ #{MSG}
            ::T::Set&.new(items)
            ^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            Array&.new #: Array[String]
            ::Set&.new(items)
          RUBY
        end

        def test_registers_one_offense_for_nested_type_arguments
          assert_offense(<<~RUBY)
            T::Hash[Integer, T::Array[T.nilable(String)]].new { |hash, key| hash[key] = [] }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            Hash.new { |hash, key| hash[key] = [] } #: Hash[Integer, Array[String?]]
          RUBY
        end

        def test_allows_ruby_constructors_and_separate_type_declarations
          assert_no_offenses(<<~RUBY)
            Array.new(2) { "item" }
            ::Hash.new(0)
            Set.new(items)
            Range.new(1, 3)
            Enumerator.new { |y| y << "item" }
            Enumerator::Lazy.new(items) { |y, item| y << item }
            Enumerator::Chain.new(first, second)
            T.let([], T::Array[String])
            T.let(Set.new, T::Set[String])
            Set.new #: Set[String]
            sig { returns(T::Hash[Symbol, T::Array[String]]) }
          RUBY
        end

        def test_allows_unrelated_namespaces_and_sorbet_types
          assert_no_offenses(<<~RUBY)
            Other::T::Array[String].new
            ::Other::T::Set.new
            Other::T::Enumerator::Lazy[String].new(items)
            T::Other[String].new
            T::Array::Other.new
            T::Enumerator::Other[String].new
            T::Struct.new
            T::Enum.new
            T::Proc.new
            CustomCollection[String].new
            collection.new
            new
            self.class.new
          RUBY
        end

        def test_allows_other_methods_on_collection_types
          assert_no_offenses(<<~RUBY)
            T::Array[String]
            T::Hash[Symbol, Integer]
            T::Set[String].name
            T::Array[String].new_method
            T::Array[String].some_class.new
          RUBY
        end

        def test_autocorrects_an_assigned_constructor
          assert_offense(<<~RUBY)
            arr = T::Array[String].new
                  ^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            arr = Array.new #: Array[String]
          RUBY
        end

        def test_preserves_multiline_blocks_and_trailing_comments
          assert_offense(<<~RUBY)
            # café
            values = T::Array[String].new(3) do |index|
                     ^^^^^^^^^^^^^^^^ #{MSG}
              index.to_s
            end # generated values
          RUBY

          assert_correction(<<~RUBY)
            # café
            values = Array.new(3) do |index|
              index.to_s
            end #: Array[String] # generated values
          RUBY
        end

        def test_preserves_multiline_arguments_and_heredoc_bodies
          assert_offense(<<~RUBY)
            values = T::Array[String].new(
                     ^^^^^^^^^^^^^^^^ #{MSG}
              2,
              "item",
            )
            defaults = T::Hash[Symbol, String].new(<<~TEXT)
                       ^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              default value
            TEXT
          RUBY

          assert_correction(<<~RUBY)
            values = Array.new(
              2,
              "item",
            ) #: Array[String]
            defaults = Hash.new(<<~TEXT) #: Hash[Symbol, String]
              default value
            TEXT
          RUBY
        end

        def test_does_not_autocorrect_when_disabled
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => false))

          assert_offense(<<~RUBY)
            arr = T::Array[String].new
                  ^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_when_an_annotation_would_swallow_code_or_target_another_expression
          assert_offense(<<~RUBY)
            consume(T::Array[String].new)
                    ^^^^^^^^^^^^^^^^ #{MSG}
            T::Array[String].new.size
            ^^^^^^^^^^^^^^^^ #{MSG}
            arr = T::Array[String].new; consume(arr)
                  ^^^^^^^^^^^^^^^^ #{MSG}
            arr = T::Array[String].new if condition
                  ^^^^^^^^^^^^^^^^ #{MSG}
            arr = (T::Array[String].new)
                   ^^^^^^^^^^^^^^^^ #{MSG}
            arr = [T::Array[String].new]
                   ^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_over_an_existing_rbs_annotation
          assert_offense(<<~RUBY)
            arr = T::Array[String].new #: Existing
                  ^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_partially_correct_an_untranslatable_type
          assert_offense(<<~RUBY)
            values = T::Hash[String, element_type].new
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_remove_comments_inside_type_arguments
          assert_offense(<<~RUBY)
            arr = T::Array[ # element type
                  ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              String
            ].new
          RUBY

          assert_no_corrections
        end

        private

        def target_cop
          ForbidTCollectionInstantiation
        end
      end
    end
  end
end
