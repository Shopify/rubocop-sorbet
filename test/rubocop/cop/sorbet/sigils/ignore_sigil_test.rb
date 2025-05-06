# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Sigils
        class IgnoreSigilTest < ::Minitest::Test
          MSG = "Sorbet/IgnoreSigil: No Sorbet sigil found in file. Try a `typed: ignore` to start (you can also use `rubocop -a` to automatically add this)."

          def setup
            @cop = IgnoreSigil.new
          end

          def test_makes_offense_if_the_strictness_is_not_at_least_ignore
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_autocorrects_by_adding_typed_ignore_to_file_without_sigil
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: ignore
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end
        end
      end
    end
  end
end
