# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::CallbackConditionalsBinding, :config) do
  subject(:cop) { described_class.new(config) }

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
  end
end
