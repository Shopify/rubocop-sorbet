# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidTUntyped, :config) do
  subject(:cop) { described_class.new(config) }

  context "a simple usage" do
    it "adds an offense" do
      expect_offense(<<~RUBY)
        T.untyped
        ^^^^^^^^^ Do not use `T.untyped`.
      RUBY
    end
  end

  context "used within a type alias" do
    it "adds offense" do
      expect_offense(<<~RUBY)
        FOO = T.type_alias { T.untyped }
                             ^^^^^^^^^ Do not use `T.untyped`.
      RUBY
    end
  end

  context "used within a type signature" do
    it "adds offense" do
      expect_offense(<<~RUBY)
        sig { params(x: T.untyped).returns(T.untyped) }
                                           ^^^^^^^^^ Do not use `T.untyped`.
                        ^^^^^^^^^ Do not use `T.untyped`.
        def foo(x)
        end
      RUBY
    end
  end

  context "used within T.bind" do
    it "adds offense" do
      expect_offense(<<~RUBY)
        def foo(x)
          T.bind(self, Y::Array[T.untyped])
                                ^^^^^^^^^ Do not use `T.untyped`.
        end
      RUBY
    end
  end
end
