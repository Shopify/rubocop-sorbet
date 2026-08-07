# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTBindTest < ::Minitest::Test
        MSG = "Do not use `T.bind`."

        def test_adds_offense_when_using_t_bind
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => false))

          assert_offense(<<~RUBY)
            T.bind(self, String)
            ^^^^^^^^^^^^^^^^^^^^ #{MSG}

            x = T.bind(self, String)
                ^^^^^^^^^^^^^^^^^^^^ #{MSG}

            ::T.bind(self, String)
            ^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_t_bind_to_an_rbs_self_assertion_when_enabled
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            # café
            T.bind(self, T::Array[String])
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

            ::T.bind(self, String)
            ^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            # café
            #: self as Array[String]

            #: self as String
          RUBY
        end

        def test_does_not_autocorrect_t_bind_on_another_value_or_in_an_assignment
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.bind(foo, String)
            ^^^^^^^^^^^^^^^^^^^ #{MSG}
            x = T.bind(self, String)
                ^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_bind_nested_in_an_expression
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(T.bind(self, String))
                    ^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_bind_with_an_existing_rbs_annotation
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.bind(self, String) #: self as Existing
            ^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        private

        def target_cop
          ForbidTBind
        end
      end
    end
  end
end
