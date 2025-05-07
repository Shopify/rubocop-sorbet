# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Sigils
        class ValidSigilTest < ::Minitest::Test
          EMPTY_SIGIL_MSG = "Sorbet sigil should not be empty."
          INVALID_SIGIL_MSG = "Invalid Sorbet sigil `%{sigil}`."
          NO_SIGIL_MSG = "No Sorbet sigil found in file. Try a `typed: %{strictness}` to start (you can also use `rubocop -a` to automatically add this)."
          MINIMUM_STRICTNESS_MSG = "Sorbet sigil should be at least `%{minimum}` got `%{actual}`."

          def setup
            @cop = target_cop.new(cop_config)
          end

          def test_does_not_require_a_sigil_by_default
            assert_no_offenses(<<~RUBY)
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_does_not_make_offense_if_there_is_a_valid_sigil
            assert_no_offenses(<<~RUBY)
              # frozen_string_literal: true
              # typed: strong
              class Foo; end
            RUBY
          end

          def test_enforces_that_the_sorbet_sigil_must_not_be_empty
            assert_offense(<<~RUBY)
              # Hello world!
              # typed:
              ^^^^^^^^ #{EMPTY_SIGIL_MSG}
              class Foo; end
            RUBY
          end

          def test_enforces_that_the_sorbet_sigil_must_be_a_valid_strictness
            assert_offense(<<~RUBY)
              # Hello world!
              # typed: foobar
              ^^^^^^^^^^^^^^^ #{format(INVALID_SIGIL_MSG, sigil: "foobar")}
              class Foo; end
            RUBY
          end

          def test_enforces_whitespace_surrounding_valid_strictness_levels
            assert_offense(<<~RUBY)
              # Hello world!
              # typed: true# rubocop:todo Sorbet/StrictSigil
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(INVALID_SIGIL_MSG, sigil: "true#")}
              class Foo; end
            RUBY
          end

          def test_does_not_change_files_with_an_invalid_sigil
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              # typed: no
              ^^^^^^^^^^^ #{format(INVALID_SIGIL_MSG, sigil: "no")}
              class Foo; end
            RUBY

            assert_correction(<<~RUBY)
              # frozen_string_literal: true
              # typed: no
              class Foo; end
            RUBY
          end

          def test_enforces_that_the_sorbet_sigil_must_exist_when_required
            @cop = target_cop.new(cop_config({ "RequireSigilOnAllFiles" => true }))
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(NO_SIGIL_MSG, strictness: "false")}
              class Foo; end
            RUBY
          end

          def test_enforces_that_the_sigil_must_be_at_the_beginning_of_the_file_when_required
            @cop = target_cop.new(cop_config({ "RequireSigilOnAllFiles" => true }))
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(NO_SIGIL_MSG, strictness: "false")}
              SOMETHING = <<~FOO
                # typed: true
              FOO
            RUBY
          end

          def test_allows_sorbet_sigil_when_required
            @cop = target_cop.new(cop_config({ "RequireSigilOnAllFiles" => true }))
            assert_no_offenses(<<~RUBY)
              # typed: true
              class Foo; end
            RUBY
          end

          def test_allows_empty_spaces_at_the_beginning_of_the_file_when_required
            @cop = target_cop.new(cop_config({ "RequireSigilOnAllFiles" => true }))
            assert_no_offenses(<<~RUBY)

              # typed: true
              class Foo; end
            RUBY
          end

          def test_makes_offense_for_double_commented_sigil
            assert_offense(<<~RUBY)
              # # typed: true
              ^^^^^^^^^^^^^^^ #{format(INVALID_SIGIL_MSG, sigil: "# # typed: true")}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: true
              class Foo; end
            RUBY
          end

          def test_makes_offense_for_double_commented_sigil_with_strictness
            assert_offense(<<~RUBY)
              # # typed: strict
              ^^^^^^^^^^^^^^^^^ #{format(INVALID_SIGIL_MSG, sigil: "# # typed: strict")}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: strict
              class Foo; end
            RUBY
          end

          def test_makes_offense_for_double_commented_sigil_with_extra_spaces
            assert_offense(<<~RUBY)
              # #  typed:  true
              ^^^^^^^^^^^^^^^^^ #{format(INVALID_SIGIL_MSG, sigil: "# #  typed:  true")}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: true
              class Foo; end
            RUBY
          end

          def test_autocorrects_by_adding_typed_false_to_file_without_sigil_when_required
            @cop = target_cop.new(cop_config({ "RequireSigilOnAllFiles" => true }))
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(NO_SIGIL_MSG, strictness: "false")}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: false
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_suggests_default_strictness_if_sigil_is_missing_when_suggested_strictness_is_true
            @cop = target_cop.new(cop_config({ "RequireSigilOnAllFiles" => true, "SuggestedStrictness" => true }))
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(NO_SIGIL_MSG, strictness: "true")}
              class Foo; end
            RUBY
          end

          def test_autocorrects_by_adding_typed_true_to_file_without_sigil_when_suggested_strictness_is_true
            @cop = target_cop.new(cop_config({ "RequireSigilOnAllFiles" => true, "SuggestedStrictness" => true }))
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(NO_SIGIL_MSG, strictness: "true")}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: true
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_suggests_default_strictness_if_sigil_is_missing_when_suggested_strictness_is_strict
            @cop = target_cop.new(cop_config({ "RequireSigilOnAllFiles" => true, "SuggestedStrictness" => "strict" }))
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(NO_SIGIL_MSG, strictness: "strict")}
              class Foo; end
            RUBY
          end

          def test_autocorrects_by_adding_typed_strict_to_file_without_sigil_when_suggested_strictness_is_strict
            @cop = target_cop.new(cop_config({ "RequireSigilOnAllFiles" => true, "SuggestedStrictness" => "strict" }))
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{format(NO_SIGIL_MSG, strictness: "strict")}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: strict
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_makes_offense_if_the_strictness_is_below_the_minimum
            @cop = target_cop.new(cop_config({ "MinimumStrictness" => true }))
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              # typed: false
              ^^^^^^^^^^^^^^ #{format(MINIMUM_STRICTNESS_MSG, minimum: "true", actual: "false")}
              class Foo; end
            RUBY
          end

          def test_makes_offense_for_double_commented_sigil_with_arbitrary_spaces
            assert_offense(<<~RUBY)
              #    # typed: false
              ^^^^^^^^^^^^^^^^^^^ Invalid Sorbet sigil `#    # typed: false`.
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: false
              class Foo; end
            RUBY
          end

          private

          def target_cop
            ValidSigil
          end
        end
      end
    end
  end
end
