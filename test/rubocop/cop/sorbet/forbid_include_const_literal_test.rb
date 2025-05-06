# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidIncludeConstLiteralTest < ::Minitest::Test
        MSG = "Sorbet/ForbidIncludeConstLiteral: `include` must only be used with constant literals as arguments"
        PREPEND_MSG = "Sorbet/ForbidIncludeConstLiteral: `prepend` must only be used with constant literals as arguments"
        EXTEND_MSG = "Sorbet/ForbidIncludeConstLiteral: `extend` must only be used with constant literals as arguments"

        def setup
          @cop = ForbidIncludeConstLiteral.new
        end

        def test_registers_offense_when_include_is_send_node
          assert_offense(<<~RUBY)
            class MyClass
              include Rails.application.routes.url_helpers
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class MyClass
              T.unsafe(self).include Rails.application.routes.url_helpers
            end
          RUBY
        end

        def test_registers_offense_when_include_is_qualified_send_node
          assert_offense(<<~RUBY)
            class MyClass
              mod = ThatMod
              include mod
              ^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class MyClass
              mod = ThatMod
              T.unsafe(self).include mod
            end
          RUBY
        end

        def test_registers_offense_when_include_is_qualified_send_node_with_helpers
          assert_offense(<<~RUBY)
            class MyClass
              include Polaris::Engine.helpers
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class MyClass
              T.unsafe(self).include Polaris::Engine.helpers
            end
          RUBY
        end

        def test_registers_offense_when_prepend_is_send_node
          assert_offense(<<~RUBY)
            class MyClass
              prepend Polaris::Engine.helpers
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{PREPEND_MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class MyClass
              T.unsafe(self).prepend Polaris::Engine.helpers
            end
          RUBY
        end

        def test_registers_offense_when_extend_is_send_node
          assert_offense(<<~RUBY)
            class MyClass
              extend Polaris::Engine.helpers
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{EXTEND_MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class MyClass
              T.unsafe(self).extend Polaris::Engine.helpers
            end
          RUBY
        end

        def test_registers_offense_when_module_includes_with_send_node
          assert_offense(<<~RUBY)
            module MyModule
              extend Polaris::Engine.helpers
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{EXTEND_MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            module MyModule
              T.unsafe(self).extend Polaris::Engine.helpers
            end
          RUBY
        end

        def test_registers_offense_when_singleton_class_includes_with_send_node
          assert_offense(<<~RUBY)
            module FilterHelper
              class << self
                include ActionView::Helpers::TagHelper
                include Rails.application.routes.url_helpers
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            module FilterHelper
              class << self
                include ActionView::Helpers::TagHelper
                T.unsafe(self).include Rails.application.routes.url_helpers
              end
            end
          RUBY
        end

        def test_does_not_register_offense_when_there_is_no_include
          assert_no_offenses(<<~RUBY)
            class MyClass
            end
          RUBY
        end

        def test_does_not_register_offense_when_include_is_qualified_name
          assert_no_offenses(<<~RUBY)
            class MyClass
              include MyModule::MyParent
            end
          RUBY
        end

        def test_does_not_register_offense_when_include_is_constant_literal
          assert_no_offenses(<<~RUBY)
            MyInclude = Rails.application.routes.url_helpers
            class MyClass
              include MyInclude
            end
          RUBY
        end

        def test_does_not_register_offense_when_anonymous_class_includes_with_send_node
          assert_no_offenses(<<~RUBY)
            UrlHelpers =
              Class.new do
                include(Rails.application.routes.url_helpers)
              end.new
          RUBY
        end

        def test_does_not_register_offense_when_include_is_called_inside_method
          assert_no_offenses(<<~RUBY)
            def foo
              m = Module.new
              prepend(m)
            end
          RUBY
        end

        def test_does_not_register_offense_when_module_extends_self
          assert_no_offenses(<<~RUBY)
            module Foo
              extend self
            end
          RUBY
        end

        def test_does_not_register_offense_when_class_extends_self
          assert_no_offenses(<<~RUBY)
            class Foo
              extend self
            end
          RUBY
        end

        def test_does_not_register_offense_when_explicit_constant_receiver_includes_send_node
          assert_no_offenses(<<~RUBY)
            module MyModule
              MyModule.include Rails.application.routes.url_helpers
            end
          RUBY
        end

        def test_does_not_register_offense_when_explicit_constant_receiver_extends_send_node
          assert_no_offenses(<<~RUBY)
            module MyModule
              MyModule.extend Rails.application.routes.url_helpers
            end
          RUBY
        end

        def test_does_not_register_offense_when_explicit_constant_receiver_prepends_send_node
          assert_no_offenses(<<~RUBY)
            module MyModule
              MyModule.prepend Rails.application.routes.url_helpers
            end
          RUBY
        end

        def test_does_not_register_offense_when_prepend_used_with_array
          assert_no_offenses(<<~RUBY)
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
    end
  end
end
