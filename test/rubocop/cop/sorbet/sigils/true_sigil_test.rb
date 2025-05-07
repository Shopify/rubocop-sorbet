# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Sigils
        class TrueSigilTest < ::Minitest::Test
          MSG = "Sorbet/TrueSigil: Sorbet sigil should be at least `true` got `false`."

          def setup
            @cop = TrueSigil.new
          end

          def test_makes_offense_if_the_strictness_is_not_at_least_true
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              # typed: false
              ^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_autocorrects_by_adding_typed_true_to_file_without_sigil
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet/TrueSigil: No Sorbet sigil found in file. Try a `typed: true` to start (you can also use `rubocop -a` to automatically add this).
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
