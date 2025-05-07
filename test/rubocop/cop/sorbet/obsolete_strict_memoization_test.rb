# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ObsoleteStrictMemoizationTest < ::Minitest::Test
        MSG = "Sorbet/ObsoleteStrictMemoization: This two-stage workaround for memoization in `#typed: strict` files is no longer necessary. See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization."

        def setup
          @cop = ObsoleteStrictMemoization.new
          @specs_without_sorbet = [
            Gem::Specification.new("foo", "0.0.1"),
            Gem::Specification.new("bar", "0.0.2"),
          ]
          ::Bundler.stubs(:locked_gems).returns(Struct.new(:specs).new([*@specs_without_sorbet, Gem::Specification.new("sorbet-static", "0.5.10210")]))
          @cop.stubs(:configured_indentation_width).returns(2)
        end

        def test_new_memoization_pattern_does_not_register_offense
          assert_no_offenses(<<~RUBY)
            def foo
              @foo ||= T.let(Foo.new, T.nilable(Foo))
            end
          RUBY
        end

        def test_obsolete_memoization_pattern_registers_offense_and_autocorrects
          assert_offense(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              @foo ||= Foo.new
            end
          RUBY

          assert_correction(<<~RUBY)
            def foo
              @foo ||= T.let(Foo.new, T.nilable(Foo))
            end
          RUBY
        end

        def test_obsolete_memoization_pattern_with_fully_qualified_t_registers_offense_and_autocorrects
          assert_offense(<<~RUBY)
            def foo
              @foo = ::T.let(@foo, ::T.nilable(Foo))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              @foo ||= Foo.new
            end
          RUBY

          assert_correction(<<~RUBY)
            def foo
              @foo ||= ::T.let(Foo.new, ::T.nilable(Foo))
            end
          RUBY
        end

        def test_obsolete_memoization_pattern_with_complex_type_registers_offense_and_autocorrects
          assert_offense(<<~RUBY)
            def client_info_hash
              @client_info_hash = T.let(@client_info_hash, T.nilable(T::Hash[Symbol, T.untyped]))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              @client_info_hash ||= client_info.to_hash
            end
          RUBY

          assert_correction(<<~RUBY)
            def client_info_hash
              @client_info_hash ||= T.let(client_info.to_hash, T.nilable(T::Hash[Symbol, T.untyped]))
            end
          RUBY
        end

        def test_obsolete_memoization_pattern_with_long_initialization_registers_offense_and_autocorrects
          assert_offense(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(SomeReallyLongTypeName______________________________________))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              @foo ||= some_really_long_initialization_expression______________________________________
            end
          RUBY

          assert_correction(<<~RUBY)
            def foo
              @foo ||= T.let(
                some_really_long_initialization_expression______________________________________,
                T.nilable(SomeReallyLongTypeName______________________________________),
              )
            end
          RUBY
        end

        def test_obsolete_memoization_pattern_with_multiline_initialization_registers_offense_and_autocorrects
          assert_offense(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              @foo ||= multiline_method_call(
                foo,
                bar,
                baz,
              )
            end
          RUBY

          assert_correction(<<~RUBY)
            def foo
              @foo ||= T.let(
                multiline_method_call(
                  foo,
                  bar,
                  baz,
                ),
                T.nilable(Foo),
              )
            end
          RUBY
        end

        def test_obsolete_memoization_pattern_with_gap_registers_offense_and_autocorrects
          assert_offense(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

              @foo ||= multiline_method_call(
                foo,
                bar,
                baz,
              )
            end
          RUBY

          assert_correction(<<~RUBY)
            def foo
              @foo ||= T.let(
                multiline_method_call(
                  foo,
                  bar,
                  baz,
                ),
                T.nilable(Foo),
              )
            end
          RUBY
        end

        def test_obsolete_memoization_pattern_not_first_line_registers_offense_and_autocorrects
          assert_offense(<<~RUBY)
            def foo
              some
              other
              code
              @foo = T.let(@foo, T.nilable(Foo))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              @foo ||= Foo.new
            end
          RUBY

          assert_correction(<<~RUBY)
            def foo
              some
              other
              code
              @foo ||= T.let(Foo.new, T.nilable(Foo))
            end
          RUBY
        end

        def test_obsolete_memoization_pattern_with_old_sorbet_version_does_not_register_offense
          ::Bundler.stubs(:locked_gems).returns(Struct.new(:specs).new([*@specs_without_sorbet, Gem::Specification.new("sorbet-static", "0.5.10209")]))
          assert_no_offenses(<<~RUBY)
            sig { returns(Foo) }
            def foo
                @foo = T.let(@foo, T.nilable(Foo))
                @foo ||= Foo.new
              end
          RUBY
        end
      end

      def test_obsolete_memoization_pattern_without_sorbet_does_not_register_offense
        ::Bundler.stubs(:locked_gems).returns(Struct.new(:specs).new(@specs_without_sorbet))
        assert_no_offenses(<<~RUBY)
          def foo
            @foo = T.let(@foo, T.nilable(Foo))
              @foo ||= Foo.new
            end
        RUBY
      end
    end
  end
end
