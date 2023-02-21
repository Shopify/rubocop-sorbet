# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidIncludeConstLiteral, :config) do
  it "adds offense when an include is a send node" do
    expect_offense(<<~RUBY)
      class MyClass
        include Rails.application.routes.url_helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it "adds offense when an include is a qualified send node" do
    expect_offense(<<~RUBY)
      class MyClass
        mod = ThatMod
        include mod
        ^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it "adds offense when an include is a qualified send node" do
    expect_offense(<<~RUBY)
      class MyClass
        include Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it "adds offense when a prepend is a send node" do
    expect_offense(<<~RUBY)
      class MyClass
        prepend Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it "adds offense when an extend is a send node" do
    expect_offense(<<~RUBY)
      class MyClass
        extend Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it "adds offense when a module includes with a send node" do
    expect_offense(<<~RUBY)
      module MyModule
        extend Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it "adds offense when a singleton class includes with a send node" do
    expect_offense(<<~RUBY)
      module FilterHelper
        class << self
          include ActionView::Helpers::TagHelper
          include Rails.application.routes.url_helpers
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
        end
      end
    RUBY
  end

  it "does not add offense when there is no include" do
    expect_no_offenses(<<~RUBY)
      class MyClass
      end
    RUBY
  end

  it "does not add offense when the include is a qualified name" do
    expect_no_offenses(<<~RUBY)
      class MyClass
        include MyModule::MyParent
      end
    RUBY
  end

  it "does not add offense when the include is a constant literal" do
    expect_no_offenses(<<~RUBY)
      MyInclude = Rails.application.routes.url_helpers
      class MyClass
        include MyInclude
      end
    RUBY
  end

  it "does not add offense when an anonymous class includes with a send node" do
    expect_no_offenses(<<~RUBY)
      UrlHelpers =
        Class.new do
          include(Rails.application.routes.url_helpers)
        end.new
    RUBY
  end

  it "does not add offense when include is called inside a method" do
    expect_no_offenses(<<~RUBY)
      def foo
        m = Module.new
        prepend(m)
      end
    RUBY
  end

  it "does not add offense when a module extend self" do
    expect_no_offenses(<<~RUBY)
      module Foo
        extend self
      end
    RUBY
  end

  it "does not add offense when a class extend self" do
    expect_no_offenses(<<~RUBY)
      class Foo
        extend self
      end
    RUBY
  end

  describe("autocorrect") do
    it("autocorrects by prefixing the include with `T.unsafe(self)`") do
      source = <<~RUBY
        class Foo
          include Rails.application.routes.url_helpers
          include(Migration[2.0])
        end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          class Foo
            T.unsafe(self).include Rails.application.routes.url_helpers
            T.unsafe(self).include(Migration[2.0])
          end
        RUBY
    end
  end
end
