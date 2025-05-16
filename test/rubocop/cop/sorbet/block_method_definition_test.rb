# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class BlockMethodDefinitionTest < ::Minitest::Test
        def setup
          @cop = BlockMethodDefinition.new
        end

        def test_registers_an_offense_when_defining_a_method_in_a_block
          assert_offense(<<~RUBY)
            yielding_method do
              def bad_method(arg0, arg1 = 1, *args, foo:, bar: nil, **kwargs, &block)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet/BlockMethodDefinition: Do not define methods in blocks (use `define_method` as a workaround).
                if arg0
                  arg0 + arg1
                end
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            yielding_method do
              define_method(:bad_method) do |arg0, arg1 = 1, *args, foo:, bar: nil, **kwargs, &block|
                if arg0
                  arg0 + arg1
                end
              end
            end
          RUBY
        end

        def test_registers_an_offense_when_defining_a_method_in_a_block_with_numbered_arguments
          assert_offense(<<~RUBY)
            yielding_method do
              puts _1

              def bad_method(args)
              ^^^^^^^^^^^^^^^^^^^^ Sorbet/BlockMethodDefinition: Do not define methods in blocks (use `define_method` as a workaround).
              end
            end
          RUBY
        end

        def test_registers_an_offense_when_defining_a_class_method_in_a_block
          assert_offense(<<~RUBY)
            yielding_method do
              def self.bad_method(args)
              ^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet/BlockMethodDefinition: Do not define methods in blocks (use `define_method` as a workaround).
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            yielding_method do
              self.define_singleton_method(:bad_method) do |args|
              end
            end
          RUBY
        end

        def test_does_not_register_an_offense_when_using_define_method_as_a_workaround
          assert_no_offenses(<<~RUBY)
            yielding_method do
              define_method(:good_method) do |args|
              end
            end
          RUBY
        end

        def test_does_not_register_an_offense_when_defining_a_top_level_method
          assert_no_offenses(<<~RUBY)
            def good_method
            end
          RUBY
        end

        def test_does_not_register_an_offense_when_defining_a_method_in_a_class
          assert_no_offenses(<<~RUBY)
            class MyClass
              def good_method
              end
            end
          RUBY
        end

        def test_does_not_register_an_offense_when_defining_a_method_in_a_named_class_defined_by_class_new
          assert_no_offenses(<<~RUBY)
            MyClass = Class.new do
              def good_method
              end
            end
          RUBY
        end

        def test_registers_an_offense_when_defining_a_method_in_an_anonymous_class
          assert_offense(<<~RUBY)
            Class.new do
              def bad_method(args)
              ^^^^^^^^^^^^^^^^^^^^ Sorbet/BlockMethodDefinition: Do not define methods in blocks (use `define_method` as a workaround).
              end
            end
          RUBY
        end
      end
    end
  end
end
