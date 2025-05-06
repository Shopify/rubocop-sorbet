# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class AllowIncompatibleOverrideTest < ::Minitest::Test
          MSG = "Sorbet/AllowIncompatibleOverride: Usage of `allow_incompatible` suggests a violation of the Liskov Substitution Principle. Instead, strive to write interfaces which respect subtyping principles and remove `allow_incompatible`"

          def setup
            @cop = AllowIncompatibleOverride.new
          end

          def test_allows_using_override_allow_incompatible_true_outside_of_sig
            assert_no_offenses(<<~RUBY)
              class Foo
                override(allow_incompatible: true)
              end
            RUBY
          end

          def test_disallows_using_override_allow_incompatible_true
            assert_offense(<<~RUBY)
              class Foo
                sig(a: Integer).override(allow_incompatible: true).void
                                         ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_disallows_using_override_allow_incompatible_true_with_block_syntax
            assert_offense(<<~RUBY)
              class Foo
                sig { override(allow_incompatible: true).void }
                               ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_disallows_using_receiver_and_override_allow_incompatible_true_with_block_syntax
            assert_offense(<<~RUBY)
              class Foo
                sig { recv.override(allow_incompatible: true).void }
                                    ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_disallows_using_override_allow_incompatible_true_with_block_syntax_and_params
            assert_offense(<<~RUBY)
              class Foo
                sig { override(allow_incompatible: true).params(a: Integer).void }
                               ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_disallows_using_override_allow_incompatible_true_even_when_other_keywords_are_present
            assert_offense(<<~RUBY)
              class Foo
                sig(a: Integer).override(allow_incompatible: true, something: :unrelated).void
                                         ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_disallows_using_override_allow_incompatible_true_even_when_the_sig_is_out_of_order
            assert_offense(<<~RUBY)
              class Foo
                sig(a: Integer).void.override(allow_incompatible: true, something: :unrelated)
                                              ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_allows_override_without_allow_incompatible
            assert_no_offenses(<<~RUBY)
              class Foo
                sig(a: Integer).override.void
              end
            RUBY
          end

          def test_doesnt_break_on_incomplete_signatures
            assert_no_offenses(<<~RUBY)
              class Foo
                sig {  }
                def foo; end
              end
            RUBY
          end
        end
      end
    end
  end
end
