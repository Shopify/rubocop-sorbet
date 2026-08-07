# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTUnsafeTest < ::Minitest::Test
        MSG = "Do not use `T.unsafe`."

        def test_adds_offense_when_using_t_unsafe
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => false))

          assert_offense(<<~RUBY)
            T.unsafe(foo)
            ^^^^^^^^^^^^^ #{MSG}

            x = T.unsafe(foo)
                ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_t_unsafe_to_an_rbs_untyped_assertion_when_enabled
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            # café
            T.unsafe(foo)
            ^^^^^^^^^^^^^ #{MSG}

            x = T.unsafe(foo)
                ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            # café
            foo #: as untyped

            x = foo #: as untyped
          RUBY
        end

        def test_does_not_autocorrect_t_unsafe_nested_in_an_expression
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(T.unsafe(foo))
                    ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_t_unsafe_with_an_existing_rbs_annotation
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.unsafe(foo) #: as Existing
            ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        private

        def target_cop
          ForbidTUnsafe
        end
      end
    end
  end
end
