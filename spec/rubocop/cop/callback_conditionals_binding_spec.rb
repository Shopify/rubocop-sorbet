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
  end

  describe("offenses") do
    it("disallows having if callback conditionals without bindings") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, if: -> { should? && ready? }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY
    end

    it("disallows having unless callback conditionals without bindings") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, unless: -> { shouldnt? }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
        end
      RUBY
    end

    it("disallows having callback conditionals without bindings in multi line blocks") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, unless: lambda {
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
             shouldnt?
          }
        end
      RUBY
    end

    it("disallows having callback conditionals without bindings in multi line blocks using do end") do
      expect_offense(<<~RUBY)
        class Post < ApplicationRecord
          before_create :do_it, unless: -> do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Callback conditionals should be bound to the right type. Use T.bind(self, Post)
             shouldnt?
          end
        end
      RUBY
    end
  end

  describe("autocorrect") do
    it("autocorrects by adding the missing binding") do
      source = <<~RUBY
        class Post < ApplicationRecord
          before_create :do_it, if: -> { should? && ready? }
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post < ApplicationRecord
          before_create :do_it, if: -> {
            T.bind(self, Post)
            should? && ready?
          }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("autocorrects with chaining if the lambda includes a single statement") do
      source = <<~RUBY
        class Post < ApplicationRecord
          before_create :do_it, if: -> { should? }
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post < ApplicationRecord
          before_create :do_it, if: -> {
            T.bind(self, Post)
            should?
          }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("autocorrects multi line blocks with a single statement") do
      source = <<~RUBY
        class Post < ApplicationRecord
          before_create :do_it, if: -> do
            should?
          end
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post < ApplicationRecord
          before_create :do_it, if: -> do
            T.bind(self, Post)
            should?
          end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("autocorrects multi line blocks with multie statements") do
      source = <<~RUBY
        class Post < ApplicationRecord
          before_create :do_it, if: -> do
            a = should?
            a && ready?
          end
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post < ApplicationRecord
          before_create :do_it, if: -> do
            T.bind(self, Post)
            a = should?
            a && ready?
          end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("autocorrects with the correct type when there are multiple parent levels") do
      source = <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> {should? && ready?}
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post
          extend Something

          validates :it, presence: true, if: -> {
            T.bind(self, Post)
            should? && ready?
          }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("autocorrects to multiline if the receiver of the send node is not self") do
      source = <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> { %w(first second).include?(name) }
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post
          extend Something

          validates :it, presence: true, if: -> {
            T.bind(self, Post)
            %w(first second).include?(name)
          }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("doesn't try to add more lines if already a do end block") do
      source = <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> do
            should? && ready?
          end
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post
          extend Something

          validates :it, presence: true, if: -> do
            T.bind(self, Post)
            should? && ready?
          end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("corrects chained methods to a single statement") do
      source = <<~RUBY
        class Post
          extend Something

          validates :it, presence: true, if: -> { something.present? }
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post
          extend Something

          validates :it, presence: true, if: -> {
            T.bind(self, Post)
            something.present?
          }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("does not try to chain if the condition is an instance variable") do
      source = <<~RUBY
        class Post
          validates :it, presence: true, if: lambda { @ready }
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post
          validates :it, presence: true, if: lambda {
            T.bind(self, Post)
            @ready
          }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("does not use fully qualified names for corrections") do
      source = <<~RUBY
        module First
          module Second
            class Post
              validates :it, presence: true, if: -> { should? }
            end
          end
        end
      RUBY

      corrected_source = <<~CORRECTED
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
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("uses fully qualified name if defined on the same line") do
      source = <<~RUBY
        class First::Second::Post
          validates :it, presence: true, if: -> { should? }
        end
      RUBY

      corrected_source = <<~CORRECTED
        class First::Second::Post
          validates :it, presence: true, if: -> {
            T.bind(self, First::Second::Post)
            should?
          }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("finds the right class when there are multiple inside a namespace") do
      source = <<~RUBY
        module First
          class Article
            validates :that, if: -> { must? }
          end

          class Second::Post
            validates :it, presence: true, if: -> { should? }
          end
        end
      RUBY

      corrected_source = <<~CORRECTED
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
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("accepts proc as block") do
      source = <<~RUBY
        class Post
          validates :it, presence: true, if: proc { should? }
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post
          validates :it, presence: true, if: proc {
            T.bind(self, Post)
            should?
          }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("does not attempt to correct blocks that already have a T.bind") do
      source = <<~RUBY
        module Namespace
          class Post
            validates :it, presence: true, if: -> { T.bind(self, Namespace::Post).should? }
          end
        end
      RUBY

      corrected_source = <<~CORRECTED
        module Namespace
          class Post
            validates :it, presence: true, if: -> { T.bind(self, Namespace::Post).should? }
          end
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end
  end
end
