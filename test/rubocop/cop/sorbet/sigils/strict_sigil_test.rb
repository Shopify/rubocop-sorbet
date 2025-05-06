# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Sigils
        class StrictSigilTest < ::Minitest::Test
          MSG = "Sorbet/StrictSigil: Sorbet sigil should be at least `strict` got `true`."

          def setup
            @cop = StrictSigil.new
          end

          def test_makes_offense_if_the_strictness_is_not_at_least_strict
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_autocorrects_by_adding_typed_strict_to_file_without_sigil
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet/StrictSigil: No Sorbet sigil found in file. Try a `typed: strict` to start (you can also use `rubocop -a` to automatically add this).
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: strict
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end
        end
      end
    end
  end
end
