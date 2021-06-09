# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ForbidSuperclassConstLiteral, :config) do
  subject(:cop) { described_class.new(config) }

  it "adds offense when a superclass is a send node" do
    expect_offense(<<~RUBY)
      class MyClass < Struct.new(:foo, :bar, :baz); end
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Superclasses must only contain constant literals
    RUBY
  end

  it "adds offense when a superclass is an index node" do
    expect_offense(<<~RUBY)
      class MyClass < ActiveRecord::Migration[6.0]; end
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Superclasses must only contain constant literals
    RUBY
  end

  it "adds offense when a superclass is an index node with a qualified name" do
    expect_offense(<<~RUBY)
      class MyClass < Component::TrustedIdScope[UserManagement::UserId]; end
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Superclasses must only contain constant literals
    RUBY
  end

  it "adds offense when the class name is qualified and the superclass is a send node" do
    expect_offense(<<~RUBY)
      class A::B < ActiveRecord::Migration[6.0]; end
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Superclasses must only contain constant literals
    RUBY
  end

  it "does not add offense when there is no superclass" do
    expect_no_offenses(<<~RUBY)
      class MyClass
        NUM = 1
      end
    RUBY
  end

  it "does not add offense when there is no send for a superclass" do
    expect_no_offenses(<<~RUBY)
      class MyClass < MyParentClass; end
    RUBY
  end

  it "does not add offense when the superclass is a qualified name" do
    expect_no_offenses(<<~RUBY)
      class MyClass < MyModule::MyParent; end
    RUBY
  end

  it "does not add offense when the superclass is a constant literal" do
    expect_no_offenses(<<~RUBY)
      MyStruct = Struct.new(:foo, :bar, :baz)
      class MyClass < MyStruct; end
    RUBY
  end

  it "does not add offense when there is no send call" do
    expect_no_offenses(<<~RUBY)
      class MyClass
        attr_reader :foo
      end
    RUBY
  end
end
