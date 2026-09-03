# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTAbsurdTest < ::Minitest::Test
        MSG = "Do not use `T.absurd`."
        DUMMY_RBS_ABSURD_VERSION = ForbidTAbsurd::MINIMUM_RBS_ABSURD_VERSION

        def setup
          stub_sorbet_static_version("0.6.99998")
        end

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

        def test_autocorrects_t_absurd_with_the_new_syntax
          stub_sorbet_static_version(DUMMY_RBS_ABSURD_VERSION)
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            def check(foo)
              T.absurd(foo)
              ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            def check(foo)
              raise #: absurd(foo)
            end
          RUBY
        end

        def test_does_not_autocorrect_t_absurd_in_an_assignment_with_the_new_syntax
          stub_sorbet_static_version(DUMMY_RBS_ABSURD_VERSION)
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            def check(foo)
              x = T.absurd(foo)
                  ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_supported_absurd_variables
          stub_sorbet_static_version(DUMMY_RBS_ABSURD_VERSION)
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            def check(foo)
              T.absurd(foo)
              ^^^^^^^^^^^^^ #{MSG}
              T.absurd(@foo)
              ^^^^^^^^^^^^^^ #{MSG}
              T.absurd(@@foo)
              ^^^^^^^^^^^^^^^ #{MSG}
              T.absurd($foo)
              ^^^^^^^^^^^^^^ #{MSG}
              T.absurd(self)
              ^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            def check(foo)
              raise #: absurd(foo)
              raise #: absurd(@foo)
              raise #: absurd(@@foo)
              raise #: absurd($foo)
              raise #: absurd(self)
            end
          RUBY
        end

        def test_does_not_autocorrect_unsupported_absurd_operands_with_the_new_syntax
          stub_sorbet_static_version(DUMMY_RBS_ABSURD_VERSION)
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.absurd(Foo)
            ^^^^^^^^^^^^^ #{MSG}
            T.absurd(foo)
            ^^^^^^^^^^^^^ #{MSG}
            T.absurd(foo.bar)
            ^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
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

        def test_new_syntax_autocorrection_preserves_a_trailing_comment
          stub_sorbet_static_version(DUMMY_RBS_ABSURD_VERSION)
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.absurd(@foo) # some comment
            ^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            raise #: absurd(@foo) # some comment
          RUBY
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

        def stub_sorbet_static_version(version)
          specs = version ? [Gem::Specification.new("sorbet-static", version)] : []
          ::Bundler.stubs(:locked_gems).returns(Struct.new(:specs).new(specs))
        end

        def target_cop
          ForbidTAbsurd
        end
      end
    end
  end
end
