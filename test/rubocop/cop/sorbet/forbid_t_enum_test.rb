# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTEnumTest < ::Minitest::Test
        MSG = "Sorbet/ForbidTEnum: Using `T::Enum` is deprecated in this codebase."

        def setup
          @cop = ForbidTEnum.new
        end

        def test_registers_offense_when_inheriting_t_enum_on_multiline_class
          assert_offense(<<~RUBY)
            class Foo < T::Enum
            ^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_registers_offense_when_inheriting_t_enum_on_singleline_class
          assert_offense(<<~RUBY)
            class Foo < T::Enum; end
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_registers_offense_when_inheriting_fully_qualified_t_enum
          assert_offense(<<~RUBY)
            class Foo < ::T::Enum; end
            ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_registers_offense_for_nested_enums
          assert_offense(<<~RUBY)
            class Foo < T::Enum
            ^^^^^^^^^^^^^^^^^^^ #{MSG}
              class Bar < T::Enum
              ^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            end
          RUBY
        end

        def test_does_not_register_offense_when_not_using_t_enum
          assert_no_offenses(<<~RUBY)
            class Foo
            end

            class Bar < Baz; end

            class Baz
              extend T::Enum
            end

            class T::Enum; end
          RUBY
        end
      end
    end
  end
end
