# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/sorbet/forbid_superclass_const_literal'

RSpec.describe(RuboCop::Cop::Sorbet::ForbidSuperclassConstLiteral, :config) do
  subject(:cop) { described_class.new(config) }

  it 'adds offense when a superclass is a send node' do
    expect_offense(<<~RUBY)
      class MyClass < Struct.new(:foo, :bar, :baz); end
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Superclasses must only contain constant literals
    RUBY
  end

  it 'adds offense when a superclass is an index node' do
    expect_offense(<<~RUBY)
      class MyClass < ActiveRecord::Migration[6.0]; end
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Superclasses must only contain constant literals
    RUBY
  end

  it 'adds offense when a superclass is an index node with a qualified name' do
    expect_offense(<<~RUBY)
      class MyClass < Component::TrustedIdScope[UserManagement::UserId]; end
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Superclasses must only contain constant literals
    RUBY
  end

  it 'adds offense when the class name is qualified and the superclass is a send node' do
    expect_offense(<<~RUBY)
      class A::B < ActiveRecord::Migration[6.0]; end
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Superclasses must only contain constant literals
    RUBY
  end

  it 'does not add offense when there is no superclass' do
    expect_no_offenses(<<~RUBY)
      class MyClass
        NUM = 1
      end
    RUBY
  end

  it 'does not add offense when there is no send for a superclass' do
    expect_no_offenses(<<~RUBY)
      class MyClass < MyParentClass; end
    RUBY
  end

  it 'does not add offense when the superclass is a qualified name' do
    expect_no_offenses(<<~RUBY)
      class MyClass < MyModule::MyParent; end
    RUBY
  end

  it 'does not add offense when the superclass is a constant literal' do
    expect_no_offenses(<<~RUBY)
      MyStruct = Struct.new(:foo, :bar, :baz)
      class MyClass < MyStruct; end
    RUBY
  end

  it 'does not add offense when there is no send call' do
    expect_no_offenses(<<~RUBY)
      class MyClass
        attr_reader :foo
      end
    RUBY
  end

  context 'autocorrect' do
    it 'autocorrects sends with an intermediate variable' do
      source = <<~RUBY
        class MyClass < Struct.new(:foo, :bar, :baz); end
      RUBY

      corrected_source = <<~RUBY
        MyClassParent = Struct.new(:foo, :bar, :baz)
        class MyClass < MyClassParent; end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects index with an intermediate variable' do
      source = <<~RUBY
        class MyOtherClass < ActiveRecord::Migration[6.0]; end
      RUBY

      corrected_source = <<~RUBY
        MyOtherClassParent = ActiveRecord::Migration[6.0]
        class MyOtherClass < MyOtherClassParent; end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects qualified names with an intermediate variable' do
      source = <<~RUBY
        class MyComponent < Component::TrustedIdScope[UserManagement::UserId]; end
      RUBY

      corrected_source = <<~RUBY
        MyComponentParent = Component::TrustedIdScope[UserManagement::UserId]
        class MyComponent < MyComponentParent; end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects and preserves qualified class names' do
      source = <<~RUBY
        class A::B < Component::TrustedIdScope[UserManagement::UserId]; end
      RUBY

      corrected_source = <<~RUBY
        A::BParent = Component::TrustedIdScope[UserManagement::UserId]
        class A::B < A::BParent; end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects and preserve indent' do
      source = <<~RUBY
        module Foo
          class MyComponent < Component::TrustedIdScope[UserManagement::UserId]; end
        end
      RUBY

      corrected_source = <<~RUBY
        module Foo
          MyComponentParent = Component::TrustedIdScope[UserManagement::UserId]
          class MyComponent < MyComponentParent; end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects nested classes' do
      source = <<~RUBY
        class OrderEditSummary
          class QuantityChange < Struct.new(:quantity, :title, :subtitle); end
        end
      RUBY

      corrected_source = <<~RUBY
        class OrderEditSummary
          QuantityChangeParent = Struct.new(:quantity, :title, :subtitle)
          class QuantityChange < QuantityChangeParent; end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end
  end
end
