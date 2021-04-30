# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::CallbackConditionalsBinding, :config) do
  subject(:cop) { described_class.new(config) }

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
          before_create :do_it, if: -> { T.bind(self, Post); should? && ready? }
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
          before_create :do_it, if: -> { T.bind(self, Post).should? }
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
            T.bind(self, Post).should?
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

          validates :it, presence: true, if: -> { should? && ready? }
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post
          extend Something

          validates :it, presence: true, if: -> { T.bind(self, Post); should? && ready? }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it("does not try to chain if the condition is an instance variable") do
      source = <<~RUBY
        class Post
          validates :it, presence: true, if: -> { @ready }
        end
      RUBY

      corrected_source = <<~CORRECTED
        class Post
          validates :it, presence: true, if: -> { T.bind(self, Post); @ready }
        end
      CORRECTED

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end
  end
end
