# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidIncludeConstLiteral, :config) do
  it "adds offense when an include is a send node" do
    expect_offense(<<~RUBY)
      class MyClass
        include Rails.application.routes.url_helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `include` must only be used with constant literals as arguments
      end
    RUBY

    expect_correction(<<~RUBY)
      class MyClass
        T.unsafe(self).include Rails.application.routes.url_helpers
      end
    RUBY
  end

  it "adds offense when an include is a qualified send node" do
    expect_offense(<<~RUBY)
      class MyClass
        mod = ThatMod
        include mod
        ^^^^^^^^^^^ `include` must only be used with constant literals as arguments
      end
    RUBY

    expect_correction(<<~RUBY)
      class MyClass
        mod = ThatMod
        T.unsafe(self).include mod
      end
    RUBY
  end

  it "adds offense when an include is a qualified send node" do
    expect_offense(<<~RUBY)
      class MyClass
        include Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `include` must only be used with constant literals as arguments
      end
    RUBY

    expect_correction(<<~RUBY)
      class MyClass
        T.unsafe(self).include Polaris::Engine.helpers
      end
    RUBY
  end

  it "adds offense when a prepend is a send node" do
    expect_offense(<<~RUBY)
      class MyClass
        prepend Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `prepend` must only be used with constant literals as arguments
      end
    RUBY

    expect_correction(<<~RUBY)
      class MyClass
        T.unsafe(self).prepend Polaris::Engine.helpers
      end
    RUBY
  end

  it "adds offense when an extend is a send node" do
    expect_offense(<<~RUBY)
      class MyClass
        extend Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `extend` must only be used with constant literals as arguments
      end
    RUBY

    expect_correction(<<~RUBY)
      class MyClass
        T.unsafe(self).extend Polaris::Engine.helpers
      end
    RUBY
  end

  it "adds offense when a module includes with a send node" do
    expect_offense(<<~RUBY)
      module MyModule
        extend Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `extend` must only be used with constant literals as arguments
      end
    RUBY

    expect_correction(<<~RUBY)
      module MyModule
        T.unsafe(self).extend Polaris::Engine.helpers
      end
    RUBY
  end

  it "adds offense when a singleton class includes with a send node" do
    expect_offense(<<~RUBY)
      module FilterHelper
        class << self
          include ActionView::Helpers::TagHelper
          include Rails.application.routes.url_helpers
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `include` must only be used with constant literals as arguments
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      module FilterHelper
        class << self
          include ActionView::Helpers::TagHelper
          T.unsafe(self).include Rails.application.routes.url_helpers
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

  it "adds no offense when an explicit constant receiver includes a send node" do
    expect_no_offenses(<<~RUBY)
      module MyModule
        MyModule.include Rails.application.routes.url_helpers
      end
    RUBY
  end

  it "adds no offense when an explicit constant receiver extends a send node" do
    expect_no_offenses(<<~RUBY)
      module MyModule
        MyModule.extend Rails.application.routes.url_helpers
      end
    RUBY
  end

  it "adds no offense when an explicit constant receiver prepends a send node" do
    expect_no_offenses(<<~RUBY)
      module MyModule
        MyModule.prepend Rails.application.routes.url_helpers
      end
    RUBY
  end

  it "does not add offense when prepend used with array" do
    expect_no_offenses(<<~RUBY)
      Config = []
      Config.prepend(one)

      module MyModule
        Config.prepend(two)
      end

      class MyClass
        Config.prepend(three)
      end
    RUBY
  end
end
