# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTMustTest < ::Minitest::Test
        MSG = "Do not use `T.must`."

        def test_adds_offense_when_using_t_must
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => false))

          assert_offense(<<~RUBY)
            T.must(foo)
            ^^^^^^^^^^^ #{MSG}

            x = T.must(foo)
                ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_t_must_to_an_rbs_non_nil_assertion_when_enabled
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            # café
            T.must(foo)
            ^^^^^^^^^^^ #{MSG}

            x = T.must(foo)
                ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            # café
            foo #: as !nil

            x = foo #: as !nil
          RUBY
        end

        def test_autocorrection_preserves_a_trailing_comment
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.must(foo) # some comment
            ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo #: as !nil # some comment
          RUBY
        end

        def test_does_not_autocorrect_t_must_nested_in_an_expression
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(T.must(foo))
                    ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_nested_t_must_calls
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.must(T.must(foo))
            ^^^^^^^^^^^^^^^^^^^ #{MSG}
                   ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_must_with_a_splat_argument
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.must(*values)
            ^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_must_with_an_existing_rbs_annotation
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.must(foo) #: as Existing
            ^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        private

        def target_cop
          ForbidTMust
        end
      end
    end
  end
end
