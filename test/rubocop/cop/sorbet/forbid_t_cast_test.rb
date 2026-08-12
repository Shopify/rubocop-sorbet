# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTCastTest < ::Minitest::Test
        MSG = "Do not use `T.cast`."

        def test_adds_offense_when_using_t_cast
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => false))

          assert_offense(<<~RUBY)
            T.cast(foo, String)
            ^^^^^^^^^^^^^^^^^^^ #{MSG}

            x = T.cast(foo, String)
                ^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_t_cast_to_an_rbs_type_assertion_when_enabled
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            # café
            T.cast(foo, T::Array[String])
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

            x = T.cast(foo, T.any(String, Symbol))
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            # café
            foo #: as Array[String]

            x = foo #: as (String | Symbol)
          RUBY
        end

        def test_adds_rbs_assertion_before_a_trailing_comment
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.cast(foo, String) # why this cast is needed
            ^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo #: as String # why this cast is needed
          RUBY
        end

        def test_autocorrects_t_cast_used_as_an_argument
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(T.cast(foo, String))
                    ^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            consume(
              foo #: as String
            )
          RUBY
        end

        def test_does_not_autocorrect_nested_t_cast_calls
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.cast(T.cast(foo, String), Object)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                   ^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_cast_with_an_existing_rbs_annotation
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.cast(foo, String) #: as Existing
            ^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_an_untranslatable_type
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.cast(foo, type)
            ^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        private

        def target_cop
          ForbidTCast
        end
      end
    end
  end
end
