# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::CallbackConditionalsBinding, :config) do
  describe("no offenses") do
    it("allows callbacks with no options") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it
        end
      RUBY
    end

    it("allows callbacks with symbol conditionals") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: :should?
        end
      RUBY
    end

    it("does not verify hashes with unknown keys") do
      expect_no_offenses(<<~RUBY)
        Validator.new.validate(key => value)
      RUBY
    end

    it("does not verify callbacks inside concerns included blocks") do
      expect_no_offenses(<<~RUBY)
        module SomeConcern
          extend ActiveSupport::Concern

          included do
            before_create :do_it, if: -> { should? }
          end
        end
      RUBY
    end

    it("does not verify callbacks using validator classes") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          validates_with PostValidator
        end
      RUBY
    end

    it("does not verify lambdas with arguments") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          validates :it, presence: true, if: -> (post) { check(post) }
        end
      RUBY
    end

    it("does not verify callbacks using validator instances") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          validates_with PostValidator.new
        end
      RUBY
    end

    it("allows callbacks using arrays for conditionals") do
      expect_no_offenses(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: [:should?, :ready?]
        end
      RUBY
    end

    it("allows blocks that already have a T.bind") do
      expect_no_offenses <<~RUBY
        module Namespace
          class Post
            validates :it, presence: true, if: -> { T.bind(self, Namespace::Post).should? }
          end
        end
      RUBY
    end
  end

  describe("offenses") do
    it("disallows having if callback conditionals without bindings") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: -> { should? && ready? }
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: -> {
            T.bind(self, Post)
            should? && ready?
          }
        end
      RUBY
    end

    it("disallows having unless callback conditionals without bindings") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, unless: -> { shouldnt? }
                                ^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, unless: -> {
            T.bind(self, Post)
            shouldnt?
          }
        end
      RUBY
    end

    it("disallows having callback conditionals without bindings in multi line blocks") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, unless: lambda {
                                ^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
            shouldnt?
          }
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, unless: lambda {
            T.bind(self, Post)
            shouldnt?
          }
        end
      RUBY
    end

    it("disallows having callback conditionals without bindings in multi line blocks using do end") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, unless: -> do
                                ^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
            shouldnt?
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, unless: -> do
            T.bind(self, Post)
            shouldnt?
          end
        end
      RUBY
    end

    it("autocorrects with chaining if the lambda includes a single statement") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: -> { should? }
                                ^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: -> {
            T.bind(self, Post)
            should?
          }
        end
      RUBY
    end

    it("autocorrects multi line blocks with a single statement") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: -> do
                                ^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
            should?
          end
        end
      RUBY

      expect_correction(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: -> do
            T.bind(self, Post)
            should?
          end
        end
      RUBY
    end

    it("autocorrects multi line blocks with multiple statements") do
      expect_offense <<~RUBY
        class Post < ApplicationRecord
          before_create :do_it, if: -> do
                                ^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
            a = should?
            a && ready?
          end
        end
      RUBY

      expect_correction <<~RUBY
        class Post < ApplicationRecord
          before_create :do_it, if: -> do
            T.bind(self, Post)
            a = should?
            a && ready?
          end
        end
      RUBY
    end

    it("autocorrects with the correct type when there are multiple parent levels") do
      expect_offense <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> {should? && ready?}
                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> {
            T.bind(self, Post)
            should? && ready?
          }
        end
      RUBY
    end

    it("autocorrects to multiline if the receiver of the send node is not self") do
      expect_offense <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> { %w(first second).include?(name) }
                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> {
            T.bind(self, Post)
            %w(first second).include?(name)
          }
        end
      RUBY
    end

    it("doesn't try to add more lines if already a do end block") do
      expect_offense <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> do
                                         ^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
            should? && ready?
          end
        end
      RUBY

      expect_correction <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> do
            T.bind(self, Post)
            should? && ready?
          end
        end
      RUBY
    end

    it("corrects chained methods to a single statement") do
      expect_offense <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> { something.present? }
                                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> {
            T.bind(self, Post)
            something.present?
          }
        end
      RUBY
    end

    it("does not try to chain if the condition is an instance variable") do
      expect_offense <<~RUBY
        class Post
          validates :it, presence: true, if: lambda { @ready }
                                         ^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction <<~RUBY
        class Post
          validates :it, presence: true, if: lambda {
            T.bind(self, Post)
            @ready
          }
        end
      RUBY
    end

    it("does not use fully qualified names for corrections") do
      expect_offense <<~RUBY
        module First
          module Second
            class Post
              validates :it, presence: true, if: -> { should? }
                                             ^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
            end
          end
        end
      RUBY

      expect_correction <<~RUBY
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

    it("uses fully qualified name if defined on the same line") do
      expect_offense <<~RUBY
        class First::Second::Post
          validates :it, presence: true, if: -> { should? }
                                         ^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, First::Second::Post)
        end
      RUBY

      expect_correction <<~RUBY
        class First::Second::Post
          validates :it, presence: true, if: -> {
            T.bind(self, First::Second::Post)
            should?
          }
        end
      RUBY
    end

    it("finds the right class when there are multiple inside a namespace") do
      expect_offense <<~RUBY
        module First
          class Article
            validates :that, if: -> { must? }
                             ^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Article)
          end

          class Second::Post
            validates :it, presence: true, if: -> { should? }
                                           ^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Second::Post)
          end
        end
      RUBY

      expect_correction <<~RUBY
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

    it("detects offenses in procs") do
      expect_offense <<~RUBY
        class Post
          validates :it, presence: true, if: proc { should? }
                                         ^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction <<~RUBY
        class Post
          validates :it, presence: true, if: proc {
            T.bind(self, Post)
            should?
          }
        end
      RUBY
    end

    it "handles the presence of both if: and unless: conditionals" do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: -> { should? }, unless: -> { shouldnt? }
                                                    ^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
                                ^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction(<<~RUBY)
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

    it "detects offenses inside single line do-end blocks" do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: -> do should end
                                ^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
          after_create :do_it, if: -> do should end
                               ^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY

      expect_correction(<<~RUBY)
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

    describe "custom indentation widths" do
      let(:config) do
        RuboCop::Config.new(
          "Layout/IndentationWidth" => {
            "Width" => 4,
          },
        )
      end

      it "indents the autocorrected code with the same width as the original code" do
        expect_offense(<<~RUBY)
          class Post < ApplicationRecord
              before_create :do_it, if: -> { should? }
                                    ^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
          end
        RUBY

        expect_correction(<<~RUBY)
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
