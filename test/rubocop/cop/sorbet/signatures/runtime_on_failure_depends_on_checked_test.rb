# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class RuntimeOnFailureDependsOnCheckedTest < ::Minitest::Test
          MSG = "Sorbet/RuntimeOnFailureDependsOnChecked: To use .on_failure you must additionally call .checked(:tests) or .checked(:always), otherwise, the .on_failure has no effect."

          def setup
            @cop = RuntimeOnFailureDependsOnChecked.new
          end

          def test_offends_when_on_failure_is_without_checked_always_or_tests
            assert_offense(<<~RUBY)
              sig { params(x: Integer).returns(Integer).on_failure(:raise) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

              sig { params(x: String).returns(String).checked(:none).on_failure(:raise) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

              sig { params(x: String).returns(String).checked().on_failure(:log) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

              sig { params(x: String).returns(String).checked(true).on_failure(:raise) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

              sig { params(x: String).returns(String).checked("tests").on_failure(:log) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

              sig { void.on_failure(:log) }
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            RUBY
          end

          def test_ok_with_checked_always_or_tests_and_on_failure
            assert_no_offenses(<<~RUBY)
              sig { params(x: Integer).returns(Integer).checked(:always).on_failure(:raise) }

              sig { params(x: Integer).returns(Integer).checked(:tests).on_failure(:log) }

              sig { void.checked(:always).on_failure(:raise) }
            RUBY
          end

          def test_ok_without_on_failure
            assert_no_offenses(<<~RUBY)
              sig { params(x: Integer).returns(Integer) }

              sig { params(x: Integer).returns(Integer).checked(:always) }
            RUBY
          end
        end
      end
    end
  end
end
