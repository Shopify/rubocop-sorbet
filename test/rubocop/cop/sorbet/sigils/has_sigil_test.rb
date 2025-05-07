# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Sigils
        class HasSigilTest < ::Minitest::Test
          EMPTY_SIGIL_MSG = "Sorbet/HasSigil: Sorbet sigil should not be empty."
          INVALID_SIGIL_MSG = "Sorbet/HasSigil: Invalid Sorbet sigil `%{sigil}`."
          NO_SIGIL_MSG = "Sorbet/HasSigil: No Sorbet sigil found in file. Try a `typed: false` to start (you can also use `rubocop -a` to automatically add this)."

          def setup
            @cop = HasSigil.new
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

          def test_enforces_that_the_sigil_must_be_at_the_beginning_of_the_file
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{NO_SIGIL_MSG}
              SOMETHING = <<~FOO
                # typed: true
              FOO
            RUBY
          end

          def test_allows_sorbet_sigil
            assert_no_offenses(<<~RUBY)
              # frozen_string_literal: true
              # typed: true
              class Foo; end
            RUBY
          end

          def test_allows_empty_spaces_at_the_beginning_of_the_file
            assert_no_offenses(<<~RUBY)

              # typed: true
              class Foo; end
            RUBY
          end

          def test_autocorrects_by_adding_typed_false_to_file_without_sigil
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{NO_SIGIL_MSG}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: false
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_adds_the_sigil_after_the_shebang_line_if_present
            assert_offense(<<~RUBY)
              #!/usr/bin/env ruby
              ^^^^^^^^^^^^^^^^^^^ #{NO_SIGIL_MSG}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              #!/usr/bin/env ruby
              # typed: false
              class Foo; end
            RUBY
          end
        end
      end
    end
  end
end
