# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class KeywordArgumentOrderingTest < ::Minitest::Test
          MSG = "Sorbet/KeywordArgumentOrdering: Optional keyword arguments must be at the end of the parameter list."

          def setup
            @cop = KeywordArgumentOrdering.new
          end

          def test_adds_offense_when_optional_arguments_are_at_the_end
            assert_offense(<<~RUBY)
              sig { params(a: Integer, b: String, blk: Proc).void }
              def foo(a: 1, b:, &blk); end
                      ^^^^ #{MSG}
            RUBY
          end

          def test_does_not_add_offense_when_order_is_correct
            assert_no_offenses(<<~RUBY)
              sig { params(a: String, b: Integer, c: Integer, blk: Proc).void }
              def foo(a, b:, c: 10, &blk); end
            RUBY
          end

          def test_does_not_add_offense_there_are_no_parameters
            assert_no_offenses(<<~RUBY)
              sig { void }
              def foo; end
            RUBY
          end

          def test_does_not_add_offense_when_splats_are_after_keyword_parameters
            assert_no_offenses(<<~RUBY)
              sig { params(a: String, b: Integer, c: String, d: Integer).void }
              def foo(a, b:, c:, **d); end
            RUBY
          end

          def test_does_not_add_offense_when_splats_are_after_optional_keyword_parameters
            assert_no_offenses(<<~RUBY)
              sig { params(a: String, b: Integer, c: String, d: Integer).void }
              def foo(a, b: 1, c: 'a', **d); end
            RUBY
          end

          def test_does_not_add_offense_when_there_is_only_a_splat
            assert_no_offenses(<<~RUBY)
              sig { params(a: String).void }
              def foo(**a); end
            RUBY
          end

          def test_does_not_add_offense_when_there_is_a_splat_after_a_standard_parameter
            assert_no_offenses(<<~RUBY)
              sig { params(a: String, b: Integer).void }
              def foo(a, **b); end
            RUBY
          end

          def test_adds_offense_when_optional_arguments_are_after_default_ones_and_there_is_a_splat
            assert_offense(<<~RUBY)
              sig { params(a: String, b: Integer, c: String, d: Integer).void }
              def foo(a, b: 1, c:, **d); end
                         ^^^^ #{MSG}
            RUBY
          end
        end
      end
    end
  end
end
