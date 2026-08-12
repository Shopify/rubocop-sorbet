# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTAbsurdTest < ::Minitest::Test
        MSG = "Do not use `T.absurd`."

        def test_adds_offense_when_using_t_absurd
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => false))

          assert_offense(<<~RUBY)
            T.absurd(foo)
            ^^^^^^^^^^^^^ #{MSG}

            x = T.absurd(foo)
                ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_t_absurd_to_an_rbs_absurd_assertion_when_enabled
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            # café
            T.absurd(foo)
            ^^^^^^^^^^^^^ #{MSG}

            x = T.absurd(foo)
                ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            # café
            foo #: absurd

            x = foo #: absurd
          RUBY
        end

        def test_autocorrection_preserves_a_trailing_comment
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.absurd(foo) # some comment
            ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo #: absurd # some comment
          RUBY
        end

        def test_autocorrects_t_absurd_after_an_inline_else
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            case foo
            when String then foo
            else T.absurd(foo) # exhaustive
                 ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            case foo
            when String then foo
            else foo #: absurd # exhaustive
            end
          RUBY
        end

        def test_autocorrects_t_absurd_after_an_inline_if_else
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            if false
            then 42
            else T.absurd(foo) # exhaustive
                 ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            if false
            then 42
            else foo #: absurd # exhaustive
            end
          RUBY
        end

        def test_autocorrects_t_absurd_after_an_inline_unless_else
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            unless true
            then 42
            else T.absurd(foo) # exhaustive
                 ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            unless true
            then 42
            else foo #: absurd # exhaustive
            end
          RUBY
        end

        def test_does_not_autocorrect_t_absurd_nested_after_an_inline_else
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            case foo
            when String then foo
            else consume(T.absurd(foo))
                         ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_absurd_nested_in_an_expression
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(T.absurd(foo))
                    ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_absurd_with_an_existing_rbs_annotation
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.absurd(foo) #: absurd
            ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        private

        def target_cop
          ForbidTAbsurd
        end
      end
    end
  end
end
