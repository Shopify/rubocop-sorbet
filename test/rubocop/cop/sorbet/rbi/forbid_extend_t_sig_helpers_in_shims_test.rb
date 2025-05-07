# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Rbi
        class ForbidExtendTSigHelpersInShimsTest < ::Minitest::Test
          MSG = "Sorbet/ForbidExtendTSigHelpersInShims: Extending T::Sig or T::Helpers in a shim is unnecessary"

          def setup
            @cop = ForbidExtendTSigHelpersInShims.new
          end

          def test_registers_offense_when_extending_t_sig_and_t_helpers
            assert_offense(<<~RUBY)
              module MyModule
                extend T::Sig
                ^^^^^^^^^^^^^ #{MSG}
                extend T::Helpers
                ^^^^^^^^^^^^^^^^^ #{MSG}

                sig { returns(String) }
                def foo; end
              end
            RUBY

            assert_correction(<<~RUBY)
              module MyModule

                sig { returns(String) }
                def foo; end
              end
            RUBY
          end

          def test_registers_offense_when_extending_t_sig_and_t_helpers_with_parenthesis
            assert_offense(<<~RUBY)
              module MyModule
                extend(T::Sig)
                ^^^^^^^^^^^^^^ #{MSG}
                extend(T::Helpers)
                ^^^^^^^^^^^^^^^^^^ #{MSG}

                sig { returns(String) }
                def foo; end
              end
            RUBY

            assert_correction(<<~RUBY)
              module MyModule

                sig { returns(String) }
                def foo; end
              end
            RUBY
          end

          def test_registers_offense_when_extending_in_empty_classes_or_modules
            assert_offense(<<~RUBY)
              module MyModule
                extend(T::Sig)
                ^^^^^^^^^^^^^^ #{MSG}
              end

              class MyClass
                extend(T::Helpers)
                ^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY

            assert_correction(<<~RUBY)
              module MyModule
              end

              class MyClass
              end
            RUBY
          end

          def test_does_not_register_offense_for_other_extends
            assert_no_offenses(<<~RUBY)
              module MyModule
                extend ActiveSupport::Concern

                def foo; end
              end
            RUBY
          end
        end
      end
    end
  end
end
