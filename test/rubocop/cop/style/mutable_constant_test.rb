# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Style
      class MutableConstantTest < ::Minitest::Test
        MSG = "Style/MutableConstant: Freeze mutable objects assigned to constants."

        def setup
          @cop = target_cop.new
        end

        def test_registers_offense_when_using_t_let_with_mutable_object
          assert_offense(<<~RUBY)
            CONST = T.let([1, 2, 3], Object)
                          ^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            CONST = T.let([1, 2, 3].freeze, Object)
          RUBY
        end

        def test_registers_offense_when_using_t_let_with_mutable_object_and_or_equals
          assert_offense(<<~RUBY)
            CONST ||= T.let([1, 2, 3], Object)
                            ^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            CONST ||= T.let([1, 2, 3].freeze, Object)
          RUBY
        end

        def test_registers_offense_when_using_mutable_object_without_t_let
          assert_offense(<<~RUBY)
            CONST = [1, 2, 3]
                    ^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            CONST = [1, 2, 3].freeze
          RUBY
        end

        def test_registers_offense_when_using_mutable_object_with_or_equals_without_t_let
          assert_offense(<<~RUBY)
            CONST ||= [1, 2, 3]
                      ^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            CONST ||= [1, 2, 3].freeze
          RUBY
        end

        def test_does_not_register_offense_when_using_immutable_object
          assert_no_offenses(<<~RUBY)
            CONST = 1
          RUBY

          assert_no_offenses(<<~RUBY)
            CONST = 1.5
          RUBY

          assert_no_offenses(<<~RUBY)
            CONST = :sym
          RUBY
        end

        def test_does_not_register_offense_when_using_frozen_object
          assert_no_offenses(<<~RUBY)
            CONST = [1, 2, 3].freeze
          RUBY
        end

        def test_does_not_register_offense_when_using_other_constant
          assert_no_offenses(<<~RUBY)
            CONST = OTHER_CONST
          RUBY

          assert_no_offenses(<<~RUBY)
            CONST = ::OTHER_CONST
          RUBY

          assert_no_offenses(<<~RUBY)
            CONST = Namespace::OTHER_CONST
          RUBY
        end

        def test_does_not_register_offense_when_using_struct
          assert_no_offenses(<<~RUBY)
            CONST = Struct.new
          RUBY

          assert_no_offenses(<<~RUBY)
            CONST = ::Struct.new
          RUBY

          assert_no_offenses(<<~RUBY)
            CONST = Struct.new(:a, :b)
          RUBY
        end

        def test_does_not_register_offense_when_using_environment_variable
          assert_no_offenses(<<~RUBY)
            CONST = ENV['foo']
          RUBY

          assert_no_offenses(<<~RUBY)
            CONST = ::ENV['foo']
          RUBY
        end

        def test_does_not_register_offense_when_using_operator_with_integer
          assert_no_offenses(<<~RUBY)
            CONST = FOO + 2
          RUBY
        end

        def test_does_not_register_offense_when_using_operator_with_float
          assert_no_offenses(<<~RUBY)
            CONST = FOO + 2.1
          RUBY
        end

        def test_does_not_register_offense_when_using_comparison_operator
          assert_no_offenses(<<~RUBY)
            CONST = FOO == BAR
          RUBY
        end

        def test_registers_offense_when_using_operator_with_string
          @cop = target_cop.new(cop_config({
            "EnforcedStyle" => "strict",
          }))

          assert_offense(<<~RUBY)
            CONST = T.let(FOO + 'bar', Object)
                          ^^^^^^^^^^^ Freeze mutable objects assigned to constants.
          RUBY

          assert_correction(<<~RUBY)
            CONST = T.let((FOO + 'bar').freeze, Object)
          RUBY
        end

        def test_registers_offense_when_using_multiple_string_concatenation
          @cop = target_cop.new(cop_config({
            "EnforcedStyle" => "strict",
          }))

          assert_offense(<<~RUBY)
            CONST = T.let('foo' + 'bar' + 'baz', Object)
                          ^^^^^^^^^^^^^^^^^^^^^ Freeze mutable objects assigned to constants.
          RUBY

          assert_correction(<<~RUBY)
            CONST = T.let(('foo' + 'bar' + 'baz').freeze, Object)
          RUBY
        end

        def test_registers_offense_when_using_heredoc
          assert_offense(<<~RUBY)
            FOO = <<-HERE
                  ^^^^^^^ #{MSG}
              SOMETHING
            HERE
          RUBY

          assert_correction(<<~RUBY)
            FOO = <<-HERE.freeze
              SOMETHING
            HERE
          RUBY
        end

        def test_does_not_register_offense_when_using_fixed_size_methods
          assert_no_offenses(<<~RUBY)
            CONST = 'foo'.count
            CONST = 'foo'.count('f')
            CONST = [1, 2, 3].count { |n| n > 2 }
            CONST = [1, 2, 3].count(2) { |n| n > 2 }
            CONST = 'foo'.length
            CONST = 'foo'.size
          RUBY
        end

        private

        def target_cop
          MutableConstant
        end
      end
    end
  end
end
