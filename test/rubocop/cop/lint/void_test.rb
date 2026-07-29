# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Lint
      class VoidTest < ::Minitest::Test
        def setup
          @cop = target_cop.new
        end

        def test_no_offense_for_rbs_absurd_in_case_when_else
          assert_no_offenses(<<~RUBY)
            def initialize(x)
              do_something
              case x
              when String
              when Integer
              else
                x #: absurd
              end
            end
          RUBY
        end

        def test_offense_for_variable_without_absurd_in_case_when_else
          assert_offense(<<~RUBY)
            def initialize(x)
              do_something
              case x
              when String
              when Integer
              else
                x
                ^ Lint/Void: Variable `x` used in void context.
              end
            end
          RUBY
        end

        def test_no_offense_for_rbs_absurd_in_case_in_else
          assert_no_offenses(<<~RUBY)
            def initialize(x)
              do_something
              case x
              in String
              in Integer
              else
                x #: absurd
              end
            end
          RUBY
        end

        def test_no_offense_for_rbs_absurd_in_void_begin_block
          assert_no_offenses(<<~RUBY)
            def initialize(x)
              do_something
              x #: absurd
            end
          RUBY
        end

        def test_offense_for_variable_without_absurd_in_void_begin_block
          assert_offense(<<~RUBY)
            def initialize(x)
              do_something
              x
              ^ Lint/Void: Variable `x` used in void context.
            end
          RUBY
        end

        def test_regular_comment_is_not_treated_as_absurd
          assert_offense(<<~RUBY)
            def initialize(x)
              do_something
              case x
              when String
              when Integer
              else
                x # not absurd
                ^ Lint/Void: Variable `x` used in void context.
              end
            end
          RUBY
        end

        def test_no_offense_for_rbs_absurd_at_top_level
          assert_no_offenses(<<~RUBY)
            x = 1
            case x
            when String
            when Integer
            else
              x #: absurd
            end
            nil
          RUBY
        end

        def test_offense_for_earlier_expression_when_later_has_absurd
          assert_offense(<<~RUBY)
            def initialize(x)
              x; y #: absurd
              ^ Lint/Void: Variable `x` used in void context.
            end
          RUBY
        end

        def test_absurd_with_trailing_text_is_not_treated_as_absurd
          assert_offense(<<~RUBY)
            def initialize(x)
              do_something
              x #: absurd extra
              ^ Lint/Void: Variable `x` used in void context.
            end
          RUBY
        end

        private

        def target_cop
          Void
        end
      end
    end
  end
end
