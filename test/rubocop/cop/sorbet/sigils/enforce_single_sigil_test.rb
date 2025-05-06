# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Sigils
        class EnforceSingleSigilTest < ::Minitest::Test
          MSG = "Sorbet/EnforceSingleSigil: Files must only contain one sigil"

          def setup
            @cop = EnforceSingleSigil.new
          end

          def test_makes_no_offense_on_empty_files
            assert_no_offenses("")
          end

          def test_makes_no_offense_with_only_one_sigil
            assert_no_offenses(<<~RUBY)
              # typed: true
              class Foo; end
            RUBY
          end

          def test_makes_no_offense_with_only_one_sigil_and_other_comments
            assert_no_offenses(<<~RUBY)
              # typed: true
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_makes_no_offense_with_only_one_sigil_and_other_sigil_in_the_middle_of_a_comment
            assert_no_offenses(<<~RUBY)
              # typed: true
              #
              # Something something `# typed: true`
              class Foo; end
            RUBY
          end

          def test_makes_offense_when_two_sigils_are_present
            assert_offense(<<~RUBY)
              # typed: true
              # typed: false
              ^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_makes_offense_on_every_extra_sigil_beyond_the_first_one
            assert_offense(<<~RUBY)
              # typed: true
              # typed: false
              ^^^^^^^^^^^^^^ #{MSG}
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_makes_offense_on_every_extra_sigil_beyond_the_first_one_when_there_are_other_comments_in_between
            assert_offense(<<~RUBY)
              # typed: true
              # typed: false
              ^^^^^^^^^^^^^^ #{MSG}
              # frozen_string_literal: true
              # hello there
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_autocorrects_duplicate_sigils_by_removing_extras
            assert_offense(<<~RUBY)
              # typed: true
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: true
              class Foo; end
            RUBY
          end

          def test_autocorrects_duplicate_sigils_by_selecting_the_first_as_the_real_sigil
            assert_offense(<<~RUBY)
              # typed: true
              # typed: false
              ^^^^^^^^^^^^^^ #{MSG}
              # typed: strict
              ^^^^^^^^^^^^^^^ #{MSG}
              # frozen_string_literal: true
              # typed: strong
              ^^^^^^^^^^^^^^^ #{MSG}
              # typed: ignore
              ^^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: true
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end
        end
      end
    end
  end
end
