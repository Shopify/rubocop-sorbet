# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module TEnum
        class ForbidComparableTEnumTest < ::Minitest::Test
          MSG = "Sorbet/ForbidComparableTEnum: Do not use `T::Enum` as a comparable object because of significant performance overhead."

          def setup
            @cop = ForbidComparableTEnum.new
          end

          def test_registers_offense_when_t_enum_includes_comparable
            assert_offense(<<~RUBY)
              class MyEnum < T::Enum
                include Comparable
                ^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_registers_offense_when_t_enum_prepends_comparable
            assert_offense(<<~RUBY)
              class MyEnum < T::Enum
                prepend Comparable
                ^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_does_not_register_offense_when_t_enum_includes_other_modules
            assert_no_offenses(<<~RUBY)
              class MyEnum < T::Enum
                include T::Sig
              end
            RUBY
          end

          def test_does_not_register_offense_when_t_enum_includes_no_other_modules
            assert_no_offenses(<<~RUBY)
              class MyEnum < T::Enum; end
            RUBY
          end

          def test_does_not_register_offense_when_comparable_is_included_in_nested_non_t_enum_class
            assert_no_offenses(<<~RUBY)
              class MyEnum < T::Enum
                class Foo
                  include Comparable
                end
              end
            RUBY
          end

          def test_does_not_register_offense_when_comparable_is_prepended_in_nested_non_t_enum_class
            assert_no_offenses(<<~RUBY)
              class MyEnum < T::Enum
                class Foo
                  prepend Comparable
                end
              end
            RUBY
          end
        end
      end
    end
  end
end
