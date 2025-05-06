# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Sigils
        class FalseSigilTest < ::Minitest::Test
          MSG = "Sorbet/FalseSigil: Sorbet sigil should be at least `false` got `ignore`."

          def setup
            @cop = FalseSigil.new
          end

          def test_makes_offense_if_the_strictness_is_not_at_least_false
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              # typed: ignore
              ^^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_autocorrects_by_adding_typed_false_to_file_without_sigil
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet/FalseSigil: No Sorbet sigil found in file. Try a `typed: false` to start (you can also use `rubocop -a` to automatically add this).
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: false
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end
        end
      end
    end
  end
end
