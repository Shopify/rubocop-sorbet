# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class SelectByIsATest < ::Minitest::Test
        MSG = "Use `grep` instead of `select` when using it only for type narrowing."

        def setup
          @old_parser_engine = ENV["PARSER_ENGINE"]
          ENV["PARSER_ENGINE"] = "parser_prism"
          @cop = target_cop.new(cop_config)
        end

        def teardown
          if @old_parser_engine
            ENV["PARSER_ENGINE"] = @old_parser_engine
          else
            ENV.delete("PARSER_ENGINE")
          end
        end

        def test_accepts_grep
          assert_no_offenses(<<~RUBY)
            strings_or_integers.grep(String)
          RUBY
        end

        def test_accepts_select_with_other_conditions
          assert_no_offenses(<<~RUBY)
            strings_or_integers.select { |e| e.is_a?(String) && e.length > 5 }
          RUBY
        end

        def test_accepts_select_with_multiple_conditions
          assert_no_offenses(<<~RUBY)
            strings_or_integers.select { |e| e.is_a?(String) || e.is_a?(Integer) }
          RUBY
        end

        def test_accepts_select_with_empty_block
          assert_no_offenses(<<~RUBY)
            strings_or_integers.select { }
          RUBY
        end

        def test_registers_offense_for_select_with_is_a
          assert_offense(<<~RUBY)
            strings_or_integers.select { |e| e.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers.grep(String)
          RUBY
        end

        def test_registers_offense_for_select_with_kind_of
          assert_offense(<<~RUBY)
            strings_or_integers.select { |e| e.kind_of?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers.grep(String)
          RUBY
        end

        def test_registers_offense_for_select_with_is_a_and_num_block
          assert_offense(<<~RUBY)
            strings_or_integers.select { _1.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers.grep(String)
          RUBY
        end

        def test_registers_offense_for_select_with_is_a_and_safe_navigation
          assert_offense(<<~RUBY)
            strings_or_integers&.select { |e| e.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers&.grep(String)
          RUBY
        end

        def test_registers_offense_for_select_with_is_a_and_num_block_and_safe_navigation
          assert_offense(<<~RUBY)
            strings_or_integers&.select { _1.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers&.grep(String)
          RUBY
        end

        def test_registers_offence_for_select_with_in_a_and_it_block
          assert_offense(<<~RUBY)
            strings_or_integers.select { it.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers.grep(String)
          RUBY
        end

        def test_registers_offence_for_select_with_in_a_and_it_block_and_safe_navigation
          assert_offense(<<~RUBY)
            strings_or_integers&.select { it.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers&.grep(String)
          RUBY
        end

        def test_registers_offense_for_filter_with_is_a
          assert_offense(<<~RUBY)
            strings_or_integers.filter { |e| e.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers.grep(String)
          RUBY
        end

        def test_registers_offense_for_filter_with_is_a_and_num_block
          assert_offense(<<~RUBY)
            strings_or_integers.filter { _1.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers.grep(String)
          RUBY
        end

        def test_registers_offense_for_filter_with_is_a_and_safe_navigation
          assert_offense(<<~RUBY)
            strings_or_integers&.filter { |e| e.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers&.grep(String)
          RUBY
        end

        def test_registers_offense_for_filter_with_is_a_and_num_block_and_safe_navigation
          assert_offense(<<~RUBY)
            strings_or_integers&.filter { _1.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers&.grep(String)
          RUBY
        end

        def test_registers_offense_for_filter_with_is_a_and_it_block
          assert_offense(<<~RUBY)
            strings_or_integers.filter { it.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers.grep(String)
          RUBY
        end

        def test_registers_offense_for_filter_with_is_a_and_it_block_and_safe_navigation
          assert_offense(<<~RUBY)
            strings_or_integers&.filter { it.is_a?(String) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            strings_or_integers&.grep(String)
          RUBY
        end

        private

        def target_cop
          SelectByIsA
        end
      end
    end
  end
end
