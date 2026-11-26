# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTAbsurdTest < ::Minitest::Test
        MSG = "Do not use `T.absurd`."

        def setup
          stub_sorbet_static_version("0.6.13595")
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

        def test_does_not_add_offense_for_rbs_absurd_assertions
          @cop = target_cop.new(cop_config)

          assert_no_offenses(<<~RUBY)
            raise #: absurd(foo)
            raise ArgumentError #: absurd(foo)
            raise ArgumentError, "unexpected" #: absurd(foo)
            Kernel.raise ArgumentError #: absurd(foo)
          RUBY
        end

        def test_autocorrects_t_absurd_to_an_rbs_absurd_assertion_when_enabled
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            def bar(foo)
              # café
              T.absurd(foo)
              ^^^^^^^^^^^^^ #{MSG}

              x = T.absurd(foo)
                  ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            def bar(foo)
              # café
              raise #: absurd(foo)

              x = raise #: absurd(foo)
            end
          RUBY
        end

        def test_autocorrects_t_absurd_on_every_kind_of_variable
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.absurd(@foo)
            ^^^^^^^^^^^^^^ #{MSG}
            T.absurd(@@foo)
            ^^^^^^^^^^^^^^^ #{MSG}
            T.absurd($foo)
            ^^^^^^^^^^^^^^ #{MSG}
            T.absurd(self)
            ^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            raise #: absurd(@foo)
            raise #: absurd(@@foo)
            raise #: absurd($foo)
            raise #: absurd(self)
          RUBY
        end

        def test_does_not_autocorrect_t_absurd_on_something_other_than_a_variable
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
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
            T.absurd(@foo) # some comment
            ^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            raise #: absurd(@foo) # some comment
          RUBY
        end

        def test_autocorrects_t_absurd_after_an_inline_else
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            case @foo
            when String then @foo
            else T.absurd(@foo) # exhaustive
                 ^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            case @foo
            when String then @foo
            else raise #: absurd(@foo) # exhaustive
            end
          RUBY
        end

        def test_autocorrects_t_absurd_after_an_inline_if_else
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            if false
            then 42
            else T.absurd(@foo) # exhaustive
                 ^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            if false
            then 42
            else raise #: absurd(@foo) # exhaustive
            end
          RUBY
        end

        def test_autocorrects_t_absurd_after_an_inline_unless_else
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            unless true
            then 42
            else T.absurd(@foo) # exhaustive
                 ^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            unless true
            then 42
            else raise #: absurd(@foo) # exhaustive
            end
          RUBY
        end

        def test_does_not_autocorrect_t_absurd_nested_after_an_inline_else
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            case @foo
            when String then @foo
            else consume(T.absurd(@foo))
                         ^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_absurd_nested_in_an_expression
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(T.absurd(@foo))
                    ^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_absurd_with_an_existing_rbs_annotation
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.absurd(@foo) #: absurd(@foo)
            ^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_to_the_legacy_rbs_absurd_assertion_on_older_sorbet
          stub_sorbet_static_version("0.6.13594")
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.absurd(foo)
            ^^^^^^^^^^^^^ #{MSG}

            x = T.absurd(foo) # some comment
                ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo #: absurd

            x = foo #: absurd # some comment
          RUBY
        end

        def test_autocorrects_to_the_legacy_rbs_absurd_assertion_without_sorbet_static
          stub_sorbet_static_version(nil)
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.absurd(foo)
            ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo #: absurd
          RUBY
        end

        private

        def target_cop
          ForbidTAbsurd
        end

        def stub_sorbet_static_version(version)
          specs = version ? [Gem::Specification.new("sorbet-static", version)] : []
          ::Bundler.stubs(:locked_gems).returns(Struct.new(:specs).new(specs))
        end
      end
    end
  end
end
