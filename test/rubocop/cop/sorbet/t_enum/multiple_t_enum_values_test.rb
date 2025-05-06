# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module TEnum
        class MultipleTEnumValuesTest < ::Minitest::Test
          MSG = "Sorbet/MultipleTEnumValues: `T::Enum` should have at least two values."

          def setup
            @cop = MultipleTEnumValues.new
          end

          def test_registers_offense_when_creating_t_enum_with_no_values
            assert_offense(<<~RUBY)
              class MyEnum < T::Enum
              ^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                enums do
                end
              end
            RUBY
          end

          def test_registers_offense_when_creating_t_enum_with_one_value
            assert_offense(<<~RUBY)
              class MyEnum < T::Enum
              ^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                enums do
                  A = new
                end
              end
            RUBY
          end

          def test_does_not_register_offense_when_creating_t_enum_with_two_values
            assert_no_offenses(<<~RUBY)
              class MyEnum < T::Enum
                enums do
                  A = new
                  B = new
                end
              end
            RUBY
          end

          def test_registers_offense_for_nested_t_enum
            assert_offense(<<~RUBY)
              class MyEnum < T::Enum
                class NestedEnum < T::Enum
                ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                  enums do
                    A = new
                  end
                end

                enums do
                  B = new
                  C = new
                end
              end
            RUBY
          end

          def test_registers_offense_for_outer_t_enum
            assert_offense(<<~RUBY)
              class MyEnum < T::Enum
              ^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                class NestedEnum < T::Enum
                  enums do
                    A = new
                    B = new
                  end
                end

                enums do
                  C = new
                end
              end
            RUBY
          end

          def test_registers_offense_for_t_enum_with_no_enums_block
            assert_offense(<<~RUBY)
              class MyEnum < T::Enum
              ^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_does_not_register_offense_for_non_t_enum_class_with_enums_block
            assert_no_offenses(<<~RUBY)
              class MyEnum < T::Enum
                class Foo
                  enums do; end
                end
              end
            RUBY
          end
        end
      end
    end
  end
end
