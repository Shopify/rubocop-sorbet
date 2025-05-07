# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class RefinementTest < ::Minitest::Test
        MSG = "Sorbet/Refinement: Do not use Ruby Refinements library as it is not supported by Sorbet."

        def setup
          @cop = Refinement.new
        end

        def test_registers_offense_for_use_of_using
          assert_offense(<<~RUBY, "my_class.rb")
            using MyRefinement
            ^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_registers_offense_for_use_of_refine
          assert_offense(<<~RUBY, "my_refinement.rb")
            module MyRefinement
              refine(String) do
              ^^^^^^^^^^^^^^ #{MSG}
                def to_s
                  "foo"
                end
              end
            end
          RUBY
        end

        def test_does_not_register_offense_for_use_of_using_with_non_const_argument
          assert_no_offenses(<<~RUBY, "my_class.rb")
            using "foo"
          RUBY
        end

        def test_does_not_register_offense_for_use_of_refine_with_non_const_argument
          assert_no_offenses(<<~RUBY, "my_refinement.rb")
            module MyRefinement
              refine "foo" do
                def to_s
                  "foo"
                end
              end
            end
          RUBY
        end

        def test_does_not_register_offense_for_use_of_refine_with_no_block_argument
          assert_no_offenses(<<~RUBY, "my_refinement.rb")
            module MyRefinement
              refine(String)
            end
          RUBY
        end

        def test_does_not_register_offense_for_use_of_refine_outside_of_module
          assert_no_offenses(<<~RUBY, "my_refinement.rb")
            module MyNamespace
              class MyClass
                refine(String) do
                  def to_s
                    "foo"
                  end
                end
              end
            end
          RUBY
        end
      end
    end
  end
end
