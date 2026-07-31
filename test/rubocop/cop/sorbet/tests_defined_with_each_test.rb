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

        def test_registers_offense_for_numbered_test_block
          assert_offense(<<~RUBY)
            ROWS.each do |row|
                 ^^^^ #{format(MSG, replacement: "test_each")}
              it { assert(_1) }
            end
          RUBY

          assert_correction(<<~RUBY)
            test_each(ROWS) do |row|
              it { assert(_1) }
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

        def test_registers_offense_for_each_of_the_test_methods
          [
            "after",
            "before",
            "context",
            "describe",
            "include_examples",
            "it",
            "let",
            "shared_examples",
            "specify",
            "subject",
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

        def test_registers_offense_for_command_call_receiver_taking_a_block
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
