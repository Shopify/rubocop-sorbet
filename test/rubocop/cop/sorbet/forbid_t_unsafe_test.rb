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

        def test_autocorrection_preserves_a_trailing_comment
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.unsafe(foo) # some comment
            ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo #: as untyped # some comment
          RUBY
        end

        def test_autocorrects_t_unsafe_used_as_a_receiver
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            T.unsafe(foo).bar.baz
            ^^^^^^^^^^^^^ #{MSG}
              T.unsafe(foo)&.bar
              ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            foo #: as untyped
              .bar.baz
              foo #: as untyped
                &.bar
          RUBY
        end

        def test_does_not_autocorrect_an_embedded_receiver
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            x = T.unsafe(foo).bar
                ^^^^^^^^^^^^^ #{MSG}
            puts T.unsafe(foo).bar
                 ^^^^^^^^^^^^^ #{MSG}
            return T.unsafe(foo).bar
                   ^^^^^^^^^^^^^ #{MSG}
            other + T.unsafe(foo).bar
                    ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_t_unsafe_used_as_an_argument
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(T.unsafe(foo))
                    ^^^^^^^^^^^^^ #{MSG}
            consume(first, T.unsafe(foo), last)
                           ^^^^^^^^^^^^^ #{MSG}
            consume(value: T.unsafe(foo))
                           ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            consume(
              foo #: as untyped
            )
            consume(
              first,
              foo, #: as untyped
              last
            )
            consume(
              value: foo #: as untyped
            )
          RUBY
        end

        def test_autocorrects_positional_and_keyword_splats
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(*T.unsafe(values))
                     ^^^^^^^^^^^^^^^^ #{MSG}
            consume(**T.unsafe(options))
                      ^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            consume(
              *(
                values #: as untyped
              )
            )
            consume(
              **(
                options #: as untyped
              )
            )
          RUBY
        end

        def test_does_not_autocorrect_a_keyword_splat_of_an_implicit_hash
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            consume(**T.unsafe(required: value, **options))
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_does_not_autocorrect_inside_a_single_line_block
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))

          assert_offense(<<~RUBY)
            assert_raises { consume(T.unsafe(foo)) }
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
