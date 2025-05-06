# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class CallbackConditionalsBindingTest < ::Minitest::Test
        MSG = "Sorbet/CallbackConditionalsBinding: Callback conditionals should be bound to the right type. Use T.bind(self, Post)"

        def setup
          @cop = CallbackConditionalsBinding.new
        end

        def test_allows_callbacks_with_no_options
          assert_no_offenses(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it
            end
          RUBY
        end

        def test_allows_callbacks_with_symbol_conditionals
          assert_no_offenses(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: :should?
            end
          RUBY
        end

        def test_does_not_verify_hashes_with_unknown_keys
          assert_no_offenses(<<~RUBY)
            Validator.new.validate(key => value)
          RUBY
        end

        def test_does_not_verify_callbacks_inside_concerns_included_blocks
          assert_no_offenses(<<~RUBY)
            module SomeConcern
              extend ActiveSupport::Concern

              included do
                before_create :do_it, if: -> { should? }
              end
            end
          RUBY
        end

        def test_does_not_verify_callbacks_using_validator_classes
          assert_no_offenses(<<~RUBY)
            class Post < ApplicationRecord
              validates_with PostValidator
            end
          RUBY
        end

        def test_does_not_verify_lambdas_with_arguments
          assert_no_offenses(<<~RUBY)
            class Post < ApplicationRecord
              validates :it, presence: true, if: -> (post) { check(post) }
            end
          RUBY
        end

        def test_does_not_verify_callbacks_using_validator_instances
          assert_no_offenses(<<~RUBY)
            class Post < ApplicationRecord
              validates_with PostValidator.new
            end
          RUBY
        end

        def test_allows_callbacks_using_arrays_for_conditionals
          assert_no_offenses(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: [:should?, :ready?]
            end
          RUBY
        end

        def test_allows_blocks_that_already_have_a_t_bind
          assert_no_offenses(<<~RUBY)
            module Namespace
              class Post
                validates :it, presence: true, if: -> { T.bind(self, Namespace::Post).should? }
              end
            end
          RUBY
        end

        def test_disallows_having_if_callback_conditionals_without_bindings
          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> { should? && ready? }
                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> {
                T.bind(self, Post)
                should? && ready?
              }
            end
          RUBY
        end

        def test_disallows_having_unless_callback_conditionals_without_bindings
          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, unless: -> { shouldnt? }
                                    ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, unless: -> {
                T.bind(self, Post)
                shouldnt?
              }
            end
          RUBY
        end

        def test_disallows_having_callback_conditionals_without_bindings_in_multi_line_blocks
          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, unless: lambda {
                                    ^^^^^^^^^^^^^^^^ #{MSG}
                shouldnt?
              }
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, unless: lambda {
                T.bind(self, Post)
                shouldnt?
              }
            end
          RUBY
        end

        def test_disallows_having_callback_conditionals_without_bindings_in_multi_line_blocks_using_do_end
          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, unless: -> do
                                    ^^^^^^^^^^^^^ Sorbet/CallbackConditionalsBinding: Callback conditionals should be bound to the right type. Use T.bind(self, Post)
                shouldnt?
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, unless: -> do
                T.bind(self, Post)
                shouldnt?
              end
            end
          RUBY
        end

        def test_autocorrects_with_chaining_if_the_lambda_includes_a_single_statement
          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> { should? }
                                    ^^^^^^^^^^^^^^^^^^ Sorbet/CallbackConditionalsBinding: Callback conditionals should be bound to the right type. Use T.bind(self, Post)
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> {
                T.bind(self, Post)
                should?
              }
            end
          RUBY
        end

        def test_autocorrects_multi_line_blocks_with_a_single_statement
          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> do
                                    ^^^^^^^^^ #{MSG}
                should?
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> do
                T.bind(self, Post)
                should?
              end
            end
          RUBY
        end

        def test_autocorrects_multi_line_blocks_with_multiple_statements
          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> do
                                    ^^^^^^^^^ #{MSG}
                a = should?
                a && ready?
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> do
                T.bind(self, Post)
                a = should?
                a && ready?
              end
            end
          RUBY
        end

        def test_autocorrects_with_the_correct_type_when_there_are_multiple_parent_levels
          assert_offense(<<~RUBY)
            class Post
              extend Something

              validates :it, presence: true, if: -> {should? && ready?}
                                             ^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post
              extend Something

              validates :it, presence: true, if: -> {
                T.bind(self, Post)
                should? && ready?
              }
            end
          RUBY
        end

        def test_autocorrects_to_multiline_if_the_receiver_of_the_send_node_is_not_self
          assert_offense(<<~RUBY)
            class Post
              extend Something

              validates :it, presence: true, if: -> { %w(first second).include?(name) }
                                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post
              extend Something

              validates :it, presence: true, if: -> {
                T.bind(self, Post)
                %w(first second).include?(name)
              }
            end
          RUBY
        end

        def test_doesnt_try_to_add_more_lines_if_already_a_do_end_block
          assert_offense(<<~RUBY)
            class Post
              extend Something

              validates :it, presence: true, if: -> do
                                             ^^^^^^^^^ #{MSG}
                should? && ready?
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post
              extend Something

              validates :it, presence: true, if: -> do
                T.bind(self, Post)
                should? && ready?
              end
            end
          RUBY
        end

        def test_corrects_chained_methods_to_a_single_statement
          assert_offense(<<~RUBY)
            class Post
              extend Something

              validates :it, presence: true, if: -> { something.present? }
                                             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post
              extend Something

              validates :it, presence: true, if: -> {
                T.bind(self, Post)
                something.present?
              }
            end
          RUBY
        end

        def test_does_not_try_to_chain_if_the_condition_is_an_instance_variable
          assert_offense(<<~RUBY)
            class Post
              validates :it, presence: true, if: lambda { @ready }
                                             ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post
              validates :it, presence: true, if: lambda {
                T.bind(self, Post)
                @ready
              }
            end
          RUBY
        end

        def test_does_not_use_fully_qualified_names_for_corrections
          assert_offense(<<~RUBY)
            module First
              module Second
                class Post
                  validates :it, presence: true, if: -> { should? }
                                                 ^^^^^^^^^^^^^^^^^^ #{MSG}
                end
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            module First
              module Second
                class Post
                  validates :it, presence: true, if: -> {
                    T.bind(self, Post)
                    should?
                  }
                end
              end
            end
          RUBY
        end

        def test_uses_fully_qualified_name_if_defined_on_the_same_line
          assert_offense(<<~RUBY)
            class First::Second::Post
              validates :it, presence: true, if: -> { should? }
                                             ^^^^^^^^^^^^^^^^^^ Sorbet/CallbackConditionalsBinding: Callback conditionals should be bound to the right type. Use T.bind(self, First::Second::Post)
            end
          RUBY

          assert_correction(<<~RUBY)
            class First::Second::Post
              validates :it, presence: true, if: -> {
                T.bind(self, First::Second::Post)
                should?
              }
            end
          RUBY
        end

        def test_finds_the_right_class_when_there_are_multiple_inside_a_namespace
          assert_offense(<<~RUBY)
            module First
              class Article
                validates :that, if: -> { must? }
                                 ^^^^^^^^^^^^^^^^ Sorbet/CallbackConditionalsBinding: Callback conditionals should be bound to the right type. Use T.bind(self, Article)
              end

              class Second::Post
                validates :it, presence: true, if: -> { should? }
                                               ^^^^^^^^^^^^^^^^^^ Sorbet/CallbackConditionalsBinding: Callback conditionals should be bound to the right type. Use T.bind(self, Second::Post)
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            module First
              class Article
                validates :that, if: -> {
                  T.bind(self, Article)
                  must?
                }
              end

              class Second::Post
                validates :it, presence: true, if: -> {
                  T.bind(self, Second::Post)
                  should?
                }
              end
            end
          RUBY
        end

        def test_detects_offenses_in_procs
          assert_offense(<<~RUBY)
            class Post
              validates :it, presence: true, if: proc { should? }
                                             ^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post
              validates :it, presence: true, if: proc {
                T.bind(self, Post)
                should?
              }
            end
          RUBY
        end

        def test_handles_the_presence_of_both_if_and_unless_conditionals
          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> { should? }, unless: -> { shouldnt? }
                                                        ^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
                                    ^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> {
                T.bind(self, Post)
                should?
              }, unless: -> {
                T.bind(self, Post)
                shouldnt?
              }
            end
          RUBY
        end

        def test_detects_offenses_inside_single_line_do_end_blocks
          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> do should end
                                    ^^^^^^^^^^^^^^^^^^^^ #{MSG}
              after_create :do_it, if: -> do should end
                                   ^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> do
                T.bind(self, Post)
                should
              end
              after_create :do_it, if: -> do
                T.bind(self, Post)
                should
              end
            end
          RUBY
        end

        def test_indents_the_autocorrected_code_with_the_same_width_as_the_original_code
          @config = RuboCop::Config.new(
            "Layout/IndentationWidth" => {
              "Width" => 4,
            },
          )

          assert_offense(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> { should? }
                                    ^^^^^^^^^^^^^^^^^^ Sorbet/CallbackConditionalsBinding: Callback conditionals should be bound to the right type. Use T.bind(self, Post)
            end
          RUBY

          assert_correction(<<~RUBY)
            class Post < ApplicationRecord
              before_create :do_it, if: -> {
                T.bind(self, Post)
                should?
              }
            end
          RUBY
        end
      end
    end
  end
end
