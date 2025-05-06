# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Sigils
        class StrongSigilTest < ::Minitest::Test
          MSG = "Sorbet/StrongSigil: Sorbet sigil should be at least `strong` got `strict`."

          def setup
            @cop = StrongSigil.new
          end

          def test_makes_offense_if_the_strongness_is_not_at_least_strong
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              # typed: strict
              ^^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_autocorrects_by_adding_typed_strong_to_file_without_sigil
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet/StrongSigil: No Sorbet sigil found in file. Try a `typed: strong` to start (you can also use `rubocop -a` to automatically add this).
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: strong
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end
        end
      end
    end
  end
end
