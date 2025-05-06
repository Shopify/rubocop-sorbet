# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidSuperclassConstLiteralTest < ::Minitest::Test
        MSG = "Sorbet/ForbidSuperclassConstLiteral: Superclasses must only contain constant literals"

        def setup
          @cop = ForbidSuperclassConstLiteral.new
        end

        def test_registers_offense_when_superclass_is_send_node
          assert_offense(<<~RUBY)
            class MyClass < Struct.new(:foo, :bar, :baz); end
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_registers_offense_when_superclass_is_index_node
          assert_offense(<<~RUBY)
            class MyClass < ActiveRecord::Migration[6.0]; end
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_registers_offense_when_superclass_is_index_node_with_qualified_name
          assert_offense(<<~RUBY)
            class MyClass < Component::TrustedIdScope[UserManagement::UserId]; end
                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_registers_offense_when_class_name_is_qualified_and_superclass_is_send_node
          assert_offense(<<~RUBY)
            class A::B < ActiveRecord::Migration[6.0]; end
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_does_not_register_offense_when_there_is_no_superclass
          assert_no_offenses(<<~RUBY)
            class MyClass
              NUM = 1
            end
          RUBY
        end

        def test_does_not_register_offense_when_there_is_no_send_for_superclass
          assert_no_offenses(<<~RUBY)
            class MyClass < MyParentClass; end
          RUBY
        end

        def test_does_not_register_offense_when_superclass_is_qualified_name
          assert_no_offenses(<<~RUBY)
            class MyClass < MyModule::MyParent; end
          RUBY
        end

        def test_does_not_register_offense_when_superclass_is_constant_literal
          assert_no_offenses(<<~RUBY)
            MyStruct = Struct.new(:foo, :bar, :baz)
            class MyClass < MyStruct; end
          RUBY
        end

        def test_does_not_register_offense_when_there_is_no_send_call
          assert_no_offenses(<<~RUBY)
            class MyClass
              attr_reader :foo
            end
          RUBY
        end
      end
    end
  end
end
