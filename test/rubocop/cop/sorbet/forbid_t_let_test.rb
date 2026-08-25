# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTLetTest < ::Minitest::Test
        MSG = "Do not use `T.let`."

        def test_adds_offense_when_using_t_let
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => false))

          assert_offense(<<~RUBY)
            T.let(foo, String)
            ^^^^^^^^^^^^^^^^^^ #{MSG}

            x = T.let(foo, String)
                ^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_t_let_to_an_rbs_type_annotation_when_enabled
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            # café
            T.let(foo, T.nilable(T::Array[String]))
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

            x = T.let(foo, T.any(String, Symbol))
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            # café
            foo #: Array[String]?

            x = foo #: (String | Symbol)
          RUBY
        end

        def test_autocorrection_preserves_a_trailing_comment
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.let(foo, Bar) # some comment
            ^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo #: Bar # some comment
          RUBY
        end

        def test_autocorrects_t_let_used_as_an_argument
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(T.let(foo, String))
                    ^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            consume(
              foo #: String
            )
          RUBY
        end

        def test_does_not_autocorrect_nested_t_let_calls
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.let(T.let(foo, String), Object)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                  ^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_let_with_an_existing_rbs_annotation
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.let(foo, String) #: Existing
            ^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_an_untranslatable_type
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.let(foo, type)
            ^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        private

        def target_cop
          ForbidTLet
        end
      end
    end
  end
end
