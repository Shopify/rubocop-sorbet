# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class TestsDefinedWithEachTest < ::Minitest::Test
        MSG = "Sorbet/TestsDefinedWithEach: Use `%{replacement}` " \
          "so Sorbet can see the tests defined in this loop."

        def setup
          @cop = TestsDefinedWithEach.new
        end

        def test_registers_offense_for_single_block_parameter
          assert_offense(<<~RUBY)
            [1, 2].each do |number|
                   ^^^^ #{format(MSG, replacement: "test_each")}
              it "spells \#{number}" do
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each([1, 2]) do |number|
              it "spells \#{number}" do
              end
            end
          RUBY
        end

        def test_destructures_multiple_block_parameters
          assert_offense(<<~RUBY)
            ROWS.each do |number, name|
                 ^^^^ #{format(MSG, replacement: "test_each")}
              it "spells \#{number}" do
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(ROWS) do |(number, name)|
              it "spells \#{number}" do
              end
            end
          RUBY
        end

        def test_registers_offense_for_hash_literal
          assert_offense(<<~RUBY)
            { "one" => 1 }.each do |name, number|
                           ^^^^ #{format(MSG, replacement: "test_each_hash")}
              it "spells \#{number}" do
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each_hash({ "one" => 1 }) do |name, number|
              it "spells \#{number}" do
              end
            end
          RUBY
        end

        def test_registers_offense_for_each_pair
          assert_offense(<<~RUBY)
            ROWS.each_pair do |name, number|
                 ^^^^^^^^^ #{format(MSG, replacement: "test_each_hash")}
              it "spells \#{number}" do
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each_hash(ROWS) do |name, number|
              it "spells \#{number}" do
              end
            end
          RUBY
        end

        def test_registers_offense_for_describe_block
          assert_offense(<<~RUBY)
            ROWS.each do |row|
                 ^^^^ #{format(MSG, replacement: "test_each")}
              describe row do
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(ROWS) do |row|
              describe row do
              end
            end
          RUBY
        end

        def test_no_offense_for_a_guard_clause_alongside_the_test
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              next if row.nil?

              it "spells \#{row}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_an_assignment_alongside_the_test
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              doubled = row * 2

              it "spells \#{doubled}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_it_behaves_like
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              it_behaves_like "a thing", row
            end
          RUBY
        end

        def test_no_offense_for_it_behaves_like_alongside_a_test
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              it "spells \#{row}" do
              end

              it_behaves_like "a thing", row
            end
          RUBY
        end

        def test_registers_offense_for_braced_test_block
          assert_offense(<<~RUBY)
            ROWS.each do |row|
                 ^^^^ #{format(MSG, replacement: "test_each")}
              it { assert(row) }
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(ROWS) do |row|
              it { assert(row) }
            end
          RUBY
        end

        # `test_each` requires the example's block to take no parameters, and `_1` is one -- as is `it`
        # from Ruby 3.4, which reaches the same check as another block type carrying an implicit one.
        def test_no_offense_for_numbered_test_block
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              it { assert(_1) }
            end
          RUBY
        end

        def test_no_offense_for_test_block_taking_a_parameter
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              it "spells \#{row}" do |example|
                assert(example)
              end
            end
          RUBY
        end

        def test_registers_offense_for_each_with_index
          assert_offense(<<~RUBY)
            ROWS.each_with_index do |row, index|
                 ^^^^^^^^^^^^^^^ #{format(MSG, replacement: "test_each")}
              it "spells \#{row}" do
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(ROWS.each_with_index.to_a) do |(row, index)|
              it "spells \#{row}" do
              end
            end
          RUBY
        end

        def test_registers_offense_for_each_with_index_on_hash_literal
          assert_offense(<<~RUBY)
            { "one" => 1 }.each_with_index do |pair, index|
                           ^^^^^^^^^^^^^^^ #{format(MSG, replacement: "test_each")}
              it "spells \#{index}" do
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each({ "one" => 1 }.each_with_index.to_a) do |(pair, index)|
              it "spells \#{index}" do
              end
            end
          RUBY
        end

        def test_registers_offense_for_call_with_empty_parentheses
          assert_offense(<<~RUBY)
            ROWS.each() do |row|
                 ^^^^ #{format(MSG, replacement: "test_each")}
              it "spells \#{row}" do
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(ROWS) do |row|
              it "spells \#{row}" do
              end
            end
          RUBY
        end

        def test_registers_offense_for_each_test_method_taking_an_argument
          [
            "context",
            "describe",
            "example",
            "example_group",
            "fcontext",
            "fdescribe",
            "fexample",
            "fit",
            "focus",
            "fspecify",
            "it",
            "pending",
            "skip",
            "specify",
            "xcontext",
            "xdescribe",
            "xexample",
            "xit",
            "xspecify",
          ].each do |method|
            assert_offense(<<~RUBY, method: method)
              ROWS.each do |row|
                   ^^^^ #{format(MSG, replacement: "test_each")}
                %{method}(row) do
                end
              end
            RUBY

            assert_correction(<<~RUBY)
              test_each(ROWS) do |row|
                #{method}(row) do
                end
              end
            RUBY
          end
        end

        # The hooks are the only accepted statements that take no argument at all.
        def test_registers_offense_for_the_hooks
          ["after", "before"].each do |method|
            assert_offense(<<~RUBY, method: method)
              ROWS.each do |row|
                   ^^^^ #{format(MSG, replacement: "test_each")}
                %{method} do
                  @row = row
                end
              end
            RUBY

            assert_correction(<<~RUBY)
              test_each(ROWS) do |row|
                #{method} do
                  @row = row
                end
              end
            RUBY
          end
        end

        # `test_each` takes an example group with exactly one argument, so metadata raises 3507.
        def test_no_offense_for_a_group_with_metadata
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              describe row, :focus do
                it "spells \#{row}" do
                end
              end
            end
          RUBY
        end

        def test_no_offense_for_an_example_with_metadata
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              it "spells \#{row}", :slow do
              end
            end
          RUBY
        end

        # The hooks take no argument there, so the `:each` scope RSpec allows raises 3507.
        def test_no_offense_for_a_hook_with_an_argument
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              before(:each) do
                @row = row
              end
            end
          RUBY
        end

        # `test_each` takes `let` and `subject` only where it is already inside an example group, so a
        # loop at class-body or file scope raises 3507 on them.
        def test_no_offense_for_let_outside_an_example_group
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              let(:thing) { row }

              it "spells \#{row}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_subject_outside_an_example_group
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              subject { row }

              it "spells \#{row}" do
              end
            end
          RUBY
        end

        # Inside an example group they are accepted, so the same loop corrects.
        def test_registers_offense_for_let_inside_an_example_group
          assert_offense(<<~RUBY)
            RSpec.describe Thing do
              ROWS.each do |row|
                   ^^^^ #{format(MSG, replacement: "test_each")}
                let(:thing) { row }

                it "spells \#{row}" do
                end
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            RSpec.describe Thing do
              test_each(ROWS) do |row|
                let(:thing) { row }

                it "spells \#{row}" do
                end
              end
            end
          RUBY
        end

        def test_registers_offense_for_subject_inside_an_example_group
          assert_offense(<<~RUBY)
            describe Thing do
              ROWS.each do |row|
                   ^^^^ #{format(MSG, replacement: "test_each")}
                subject { row }

                it "spells \#{row}" do
                end
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            describe Thing do
              test_each(ROWS) do |row|
                subject { row }

                it "spells \#{row}" do
                end
              end
            end
          RUBY
        end

        # `let` needs a block there, so the memoized-helper-less form raises 3507.
        def test_no_offense_for_let_without_a_block
          assert_no_offenses(<<~RUBY)
            describe Thing do
              ROWS.each do |row|
                let(:thing)
              end
            end
          RUBY
        end

        # The shared-example helpers are exempt from the block and arity rules, so a bare
        # `include_examples` corrects even though it takes no block.
        def test_registers_offense_for_include_examples
          assert_offense(<<~RUBY)
            ROWS.each do |row|
                 ^^^^ #{format(MSG, replacement: "test_each")}
              include_examples "a thing", row
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(ROWS) do |row|
              include_examples "a thing", row
            end
          RUBY
        end

        # A splat is the one argument form the shared-example helpers will not take there.
        def test_no_offense_for_include_context_with_a_splat
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              include_context(*row, enabled: true)
            end
          RUBY
        end

        def test_registers_offense_for_shared_examples
          assert_offense(<<~RUBY)
            ROWS.each do |row|
                 ^^^^ #{format(MSG, replacement: "test_each")}
              shared_examples "a thing" do
                it "spells \#{row}" do
                end
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(ROWS) do |row|
              shared_examples "a thing" do
                it "spells \#{row}" do
                end
              end
            end
          RUBY
        end

        # `Minitest::Spec` defines `describe`, `it`, `before` and `after` itself, so a spec-style minitest
        # suite corrects the same way. Modelled on `Arel::Spec` in Rails.
        def test_registers_offense_in_a_minitest_spec_class
          assert_offense(<<~RUBY)
            class MathTest < Arel::Spec
              %i[* /].each do |operator|
                      ^^^^ #{format(MSG, replacement: "test_each")}
                it "average is compatible with \#{operator}" do
                  assert(table[:id].average.public_send(operator, 2))
                end
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class MathTest < Arel::Spec
              test_each(%i[* /]) do |operator|
                it "average is compatible with \#{operator}" do
                  assert(table[:id].average.public_send(operator, 2))
                end
              end
            end
          RUBY
        end

        # Sorbet rewrites the `test` macro only for the direct statements of a class body, and its
        # `test_each` rewriter has no arm for it, so correcting this loop would raise 3507.
        def test_no_offense_for_the_active_support_test_macro
          assert_no_offenses(<<~RUBY)
            class I18nValidationTest < ActiveSupport::TestCase
              COMMON_CASES.each do |name, options|
                test "validates_confirmation_of on generated message \#{name}" do
                  assert(@person.valid?)
                end
              end
            end
          RUBY
        end

        # `setup` and `teardown` are rewritten alongside the `test` macro, not by the `test_each` rewriter.
        def test_no_offense_for_setup_and_teardown
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              setup do
                @row = row
              end

              teardown do
                @row = nil
              end
            end
          RUBY
        end

        # `test_each` has no `define_method` arm either, so a classic minitest loop is left alone.
        def test_no_offense_for_define_method
          assert_no_offenses(<<~RUBY)
            SINGULAR_TO_PLURAL.each do |singular|
              define_method "test_pluralize_singular_\#{singular}" do
                assert_equal(plural, ActiveSupport::Inflector.pluralize(singular))
              end
            end
          RUBY
        end

        # A `def` is not a send, so there is no `test_each` shape to correct a classic minitest test into.
        def test_no_offense_for_a_test_defined_with_def
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              def test_titleize
                assert_equal(row, ActiveSupport::Inflector.titleize(row))
              end
            end
          RUBY
        end

        # Sorbet rejects `test_each` inside `test_each`, a bare `each` block inside `test_each`, and a
        # `describe` wrapping the inner `test_each`, so there is no correction to make at either level.
        def test_no_offense_for_nested_loops
          assert_no_offenses(<<~RUBY)
            OUTER.each do |a|
              INNER.each do |b|
                it { assert(a + b) }
              end
            end
          RUBY
        end

        def test_no_offense_for_a_loop_nested_in_a_loop_with_tests_of_its_own
          assert_no_offenses(<<~RUBY)
            OUTER.each do |a|
              it { assert(a) }

              INNER.each do |b|
                it { assert(b) }
              end
            end
          RUBY
        end

        def test_no_offense_for_test_method_called_on_a_receiver
          assert_no_offenses(<<~RUBY)
            records.each do |record|
              record.before(cutoff)
            end
          RUBY
        end

        def test_no_offense_for_safe_navigation
          assert_no_offenses(<<~RUBY)
            ROWS&.each do |row|
              it "spells \#{row}" do
              end
            end
          RUBY
        end

        # Both loops iterate the receiver, since `each` and `test_each` alike return it. Correcting them
        # together used to raise `Parser::ClobberingError` from the overlapping corrections.
        def test_corrects_loop_chained_onto_another_loop
          assert_offense(<<~RUBY)
            ROWS.each do |a, b|
                 ^^^^ #{format(MSG, replacement: "test_each")}
              it { assert(a) }
            end.each do |c, d|
              it { assert(c) }
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(test_each(ROWS) do |(a, b)|
              it { assert(a) }
            end) do |(c, d)|
              it { assert(c) }
            end
          RUBY
        end

        def test_registers_offense_for_chained_receiver
          assert_offense(<<~RUBY)
            config.settings.each do |key, value|
                            ^^^^ #{format(MSG, replacement: "test_each")}
              it "spells \#{key}" do
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(config.settings) do |(key, value)|
              it "spells \#{key}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_comment_before_the_selector
          assert_no_offenses(<<~RUBY)
            ROWS # rubocop:disable Some/Cop
              .each do |a, b|
                it { assert(a) }
              end
          RUBY
        end

        def test_no_offense_for_command_call_receiver_taking_a_block
          assert_no_offenses(<<~RUBY)
            rows_for ENV do |x|
              x
            end.each do |number, name|
              it { assert(number) }
            end
          RUBY
        end

        def test_registers_offense_for_command_call_receiver_taking_a_block_on_ruby_3_4
          # `unparenthesizable?` reads the cop's own `target_ruby_version`, not the test
          # framework's `ruby_version` (which only controls how the example source is parsed) --
          # so the cop needs a config that actually declares TargetRubyVersion. Extend the real
          # default configuration rather than a bare hash, so unrelated defaults (e.g. whether
          # offense messages are prefixed with the cop name) still match every other test here.
          default_config = RuboCop::ConfigLoader.default_configuration
          hash = default_config.to_h.merge(
            "AllCops" => default_config.for_all_cops.merge("TargetRubyVersion" => 3.4),
          )
          @cop = TestsDefinedWithEach.new(RuboCop::Config.new(hash, default_config.loaded_path))

          assert_offense(<<~RUBY)
            rows_for ENV do |x|
              x
            end.each do |number, name|
                ^^^^ #{format(MSG, replacement: "test_each")}
              it { assert(number) }
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(rows_for ENV do |x|
              x
            end) do |(number, name)|
              it { assert(number) }
            end
          RUBY
        end

        def test_registers_offense_for_parenthesized_call_receiver_taking_a_block
          assert_offense(<<~RUBY)
            rows_for(ENV) do |x|
              x
            end.each do |number, name|
                ^^^^ #{format(MSG, replacement: "test_each")}
              it { assert(number) }
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(rows_for(ENV) do |x|
              x
            end) do |(number, name)|
              it { assert(number) }
            end
          RUBY
        end

        def test_no_offense_for_lone_parameter_with_each_with_index
          assert_no_offenses(<<~RUBY)
            ROWS.each_with_index do |row|
              it "spells \#{row}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_block_parameters_with_a_trailing_comma
          assert_no_offenses(<<~RUBY)
            ROWS.each do |number, name,|
              it "spells \#{number}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_loop_that_defines_no_tests
          assert_no_offenses(<<~RUBY)
            it "sums the rows" do
              ROWS.each do |row|
                total += row
              end
            end
          RUBY
        end

        def test_no_offense_for_empty_loop_body
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
            end
          RUBY
        end

        def test_no_offense_without_block_parameters
          assert_no_offenses(<<~RUBY)
            ROWS.each do
              it "spells one" do
              end
            end
          RUBY
        end

        def test_no_offense_for_numbered_block_parameter
          assert_no_offenses(<<~RUBY)
            ROWS.each { describe(_1) { } }
          RUBY
        end

        def test_no_offense_for_it_block_parameter
          assert_no_offenses(<<~RUBY)
            ROWS.each { describe(it) { } }
          RUBY
        end

        def test_no_offense_for_splat_block_parameter
          assert_no_offenses(<<~RUBY)
            ROWS.each do |*row|
              it "spells \#{row}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_already_destructured_block_parameter
          assert_no_offenses(<<~RUBY)
            ROWS.each do |(number, name)|
              it "spells \#{number}" do
              end
            end
          RUBY
        end

        def test_no_offense_without_receiver
          assert_no_offenses(<<~RUBY)
            each do |row|
              it "spells \#{row}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_a_class_constant_receiver
          assert_no_offenses(<<~RUBY)
            Question::Choice.each do |choice|
              it { assert(choice) }
            end
          RUBY
        end

        def test_registers_offense_for_a_value_constant_receiver
          assert_offense(<<~RUBY)
            TRACKED_METHODS.each do |method|
                            ^^^^ #{format(MSG, replacement: "test_each")}
              it { assert(method) }
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(TRACKED_METHODS) do |method|
              it { assert(method) }
            end
          RUBY
        end

        def test_no_offense_when_loop_method_takes_arguments
          assert_no_offenses(<<~RUBY)
            ROWS.each_pair(1) do |name, number|
              it "spells \#{number}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_other_enumerable_methods
          assert_no_offenses(<<~RUBY)
            ROWS.map do |row|
              it "spells \#{row}" do
              end
            end
          RUBY
        end

        def test_no_offense_for_non_test_block_body
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              row.tap do |value|
                value.freeze
              end
            end
          RUBY
        end

        def test_no_offense_for_non_test_statement_body
          assert_no_offenses(<<~RUBY)
            ROWS.each do |row|
              register(row)
            end
          RUBY
        end

        def test_no_offense_when_already_using_test_each
          assert_no_offenses(<<~RUBY)
            test_each(ROWS) do |row|
              it "spells \#{row}" do
              end
            end
          RUBY
        end
      end
    end
  end
end
