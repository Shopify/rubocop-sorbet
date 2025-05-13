# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class EmptyLineAfterSigTest < ::Minitest::Test
          MSG = "Sorbet/EmptyLineAfterSig: Extra empty line or comment detected"

          def setup
            @cop = EmptyLineAfterSig.new
          end

          def test_does_not_register_offense_with_no_empty_line_between_sig_and_method_definition
            assert_no_offenses(<<~RUBY)
              sig { void }
              def foo; end
            RUBY
          end

          def test_does_not_register_offense_for_surrounding_empty_lines
            assert_no_offenses(<<~RUBY)
              extend T::Sig

              sig { void }
              def foo; end

              bar!
            RUBY
          end

          def test_does_not_register_offense_if_sig_and_definition_are_on_same_line
            assert_no_offenses(<<~RUBY)
              sig { void }; def foo; end
            RUBY
          end

          def test_does_not_register_offense_if_method_definition_has_multiple_sigs
            assert_no_offenses(<<~RUBY)
              sig { void }
              sig { params(foo: String).void }
              def bar(foo); end
            RUBY
          end

          def test_registers_offense_for_normal_method_definition
            assert_offense(<<~RUBY)
              sig { void }

              ^{} #{MSG}
              def foo; end
            RUBY

            assert_correction(<<~RUBY)
              sig { void }
              def foo; end
            RUBY
          end

          def test_registers_offense_for_singleton_method_definition
            assert_offense(<<~RUBY)
              sig { void }

              ^{} #{MSG}
              def self.foo; end
            RUBY

            assert_correction(<<~RUBY)
              sig { void }
              def self.foo; end
            RUBY
          end

          def test_registers_offense_for_attr_reader
            assert_offense(<<~RUBY)
              sig { void }

              ^{} #{MSG}
              attr_reader :bar
            RUBY

            assert_correction(<<~RUBY)
              sig { void }
              attr_reader :bar
            RUBY
          end

          def test_registers_offense_for_multiline_sigs_with_indentation
            assert_offense(<<~RUBY)
              module Example
                extend T::Sig

                sig do
                  params(
                    session: String,
                  ).void
                end

              ^{} #{MSG}
                def initialize(
                  session:
                )
                  @session = session
                end
              end
            RUBY

            assert_correction(<<~RUBY)
              module Example
                extend T::Sig

                sig do
                  params(
                    session: String,
                  ).void
                end
                def initialize(
                  session:
                )
                  @session = session
                end
              end
            RUBY
          end

          def test_registers_offense_for_comments_in_between_sig_and_method_definition
            assert_offense(<<~RUBY)
              module Example
                extend T::Sig

                sig do
                  params(
                    session: String,
                  ).void
                end
                # Session: string
              ^^^^^^^^^^^^^^^^^^^ #{MSG}
                def initialize(
                  session:
                )
                  @session = session
                end
              end
            RUBY

            assert_correction(<<~RUBY)
              module Example
                extend T::Sig

                # Session: string
                sig do
                  params(
                    session: String,
                  ).void
                end
                def initialize(
                  session:
                )
                  @session = session
                end
              end
            RUBY
          end

          def test_registers_offense_for_empty_line_and_comments_in_between_sig_and_method_definition
            assert_offense(<<~RUBY)
              sig { params(session: String).void }

              ^{} #{MSG}

              # Session: string

              # More stuff

              # on more lines

              def initialize(session:)
                @session = session
              end
            RUBY

            assert_correction(<<~RUBY)
              # Session: string
              # More stuff
              # on more lines
              sig { params(session: String).void }
              def initialize(session:)
                @session = session
              end
            RUBY
          end

          def test_registers_offense_if_sig_is_not_first_expression_on_line
            assert_offense(<<~RUBY)
              true; sig { void }
              # Comment
              ^^^^^^^^^ #{MSG}
              def m; end
            RUBY

            assert_correction(<<~RUBY)
              # Comment
              true; sig { void }
              def m; end
            RUBY
          end

          def test_registers_offense_for_empty_line_following_multiple_sigs
            assert_offense(<<~RUBY)
              sig { void }
              sig { params(foo: String).void }

              ^{} #{MSG}
              def bar(foo); end
            RUBY

            assert_correction(<<~RUBY)
              sig { void }
              sig { params(foo: String).void }
              def bar(foo); end
            RUBY
          end

          def test_registers_offense_for_empty_line_in_between_multiple_sigs
            assert_offense(<<~RUBY)
              sig { void }

              ^{} #{MSG}
              sig { params(foo: String).void }
              def bar(foo); end
            RUBY

            assert_correction(<<~RUBY)
              sig { void }
              sig { params(foo: String).void }
              def bar(foo); end
            RUBY
          end

          def test_registers_no_offense_when_there_is_only_a_sig
            assert_no_offenses(<<~RUBY)
              sig { void }
            RUBY
          end

          def test_registers_no_offense_when_there_is_only_a_method_definition
            assert_no_offenses(<<~RUBY)
              def foo; end
            RUBY
          end

          def test_does_not_move_rubocop_directive_comments
            assert_no_offenses(<<~RUBY)
              sig { void }
              # rubocop:disable Style/Foo
              def foo; end
              # rubocop:enable Style/Foo
            RUBY
          end

          def test_does_not_move_rubocop_todo_comments
            assert_no_offenses(<<~RUBY)
              sig { void }
              # rubocop:todo Style/Foo
              def foo; end
            RUBY
          end

          def test_does_not_move_rubocop_comments_but_moves_other_comments
            assert_offense(<<~RUBY)
              # rubocop:todo Style/Foo
              sig { void }
              # rubocop:enable Style/Foo
              ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # Comment
              def foo; end
            RUBY

            assert_correction(<<~RUBY)
              # rubocop:todo Style/Foo
              # Comment
              sig { void }
              # rubocop:enable Style/Foo
              def foo; end
            RUBY
          end
        end
      end
    end
  end
end
