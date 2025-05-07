# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class BuggyObsoleteStrictMemoizationTest < ::Minitest::Test
        MSG = "Sorbet/BuggyObsoleteStrictMemoization: This might be a mistaken variant of the two-stage workaround that used to be needed for memoization in `#typed: strict` files. See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization."

        def setup
          @cop = BuggyObsoleteStrictMemoization.new
          @specs_without_sorbet = [
            Gem::Specification.new("foo", "0.0.1"),
            Gem::Specification.new("bar", "0.0.2"),
          ]
          ::Bundler.stubs(:locked_gems).returns(
            Struct.new(:specs).new([
              *@specs_without_sorbet,
              Gem::Specification.new("sorbet-static", "0.5.10210"),
            ]),
          )
          @cop.stubs(:configured_indentation_width).returns(2)
        end

        def test_new_memoization_pattern_does_not_register_offense
          assert_no_offenses(<<~RUBY)
            def foo
              @foo ||= T.let(Foo.new, T.nilable(Foo))
            end
          RUBY
        end

        def test_correct_obsolete_memoization_pattern_does_not_register_offense
          assert_no_offenses(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
              @foo ||= Foo.new
            end
          RUBY
        end

        def test_correct_obsolete_memoization_pattern_with_fully_qualified_t_does_not_register_offense
          assert_no_offenses(<<~RUBY)
            def foo
              @foo = ::T.let(@foo, ::T.nilable(Foo))
              @foo ||= Foo.new
            end
          RUBY
        end

        def test_correct_obsolete_memoization_pattern_with_complex_type_does_not_register_offense
          assert_no_offenses(<<~RUBY)
            def client_info_hash
              @client_info_hash = T.let(@client_info_hash, T.nilable(T::Hash[Symbol, T.untyped]))
              @client_info_hash ||= client_info.to_hash
            end
          RUBY
        end

        def test_correct_obsolete_memoization_pattern_with_multiline_initialization_does_not_register_offense
          assert_no_offenses(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
              @foo ||= multiline_method_call(
                foo,
                bar,
                baz,
              )
            end
          RUBY
        end

        def test_correct_obsolete_memoization_pattern_with_gap_between_lines_does_not_register_offense
          assert_no_offenses(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))

              @foo ||= multiline_method_call(
                foo,
                bar,
                baz,
              )
            end
          RUBY
        end

        def test_correct_obsolete_memoization_pattern_with_non_empty_lines_between_does_not_register_offense
          assert_no_offenses(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
             some_other_computation
              @foo ||= multiline_method_call(
                foo,
                bar,
                baz,
              )
            end
          RUBY
        end

        def test_correct_obsolete_memoization_pattern_not_first_line_does_not_register_offense
          assert_no_offenses(<<~RUBY)
            def foo
              some
              other
              code
              @foo = T.let(@foo, T.nilable(Foo))
              @foo ||= Foo.new
            end
          RUBY
        end

        def test_mistaken_variant_without_sorbet_does_not_register_offense
          ::Bundler.stubs(:locked_gems).returns(
            Struct.new(:specs).new(@specs_without_sorbet),
          )

          assert_no_offenses(<<~RUBY)
            sig { returns(Foo) }
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
              @foo ||= Foo.new
            end
          RUBY
        end

        def test_mistaken_variant_registers_offense_and_autocorrects
          assert_offense(<<~RUBY)
            def foo
              @foo = T.let(nil, T.nilable(Foo))
                           ^^^ #{MSG}
              @foo ||= Foo.new
            end
          RUBY

          assert_correction(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
              @foo ||= Foo.new
            end
          RUBY
        end
      end
    end
  end
end
