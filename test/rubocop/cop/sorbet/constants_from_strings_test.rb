# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ConstantsFromStringsTest < ::Minitest::Test
        def setup
          @cop = ConstantsFromStrings.new
        end

        def test_registers_offense_for_constantize
          assert_offense(<<~RUBY)
            klass = "Foo".constantize
                          ^^^^^^^^^^^ #{error_message("constantize")}
          RUBY
        end

        def test_registers_offense_for_constantize_with_safe_navigation
          assert_offense(<<~RUBY)
            klass = class_name&.constantize
                                ^^^^^^^^^^^ #{error_message("constantize")}
          RUBY
        end

        def test_registers_offense_for_safe_constantize
          assert_offense(<<~RUBY)
            klass = "Foo".safe_constantize
                          ^^^^^^^^^^^^^^^^ #{error_message("safe_constantize")}
          RUBY
        end

        def test_registers_offense_for_safe_constantize_with_safe_navigation
          assert_offense(<<~RUBY)
            klass = class_name&.safe_constantize
                                ^^^^^^^^^^^^^^^^ #{error_message("safe_constantize")}
          RUBY
        end

        def test_registers_offense_for_const_get_with_receiver
          assert_offense(<<~RUBY)
            klass = Object.const_get("Foo")
                           ^^^^^^^^^ #{error_message("const_get")}
          RUBY
        end

        def test_registers_offense_for_const_get_without_receiver
          assert_offense(<<~RUBY)
            klass = const_get("Foo")
                    ^^^^^^^^^ #{error_message("const_get")}
          RUBY
        end

        def test_registers_offense_for_constants_with_receiver
          assert_offense(<<~RUBY)
            klass = Object.constants.select { |c| c.name == "Foo" }
                           ^^^^^^^^^ #{error_message("constants")}
          RUBY
        end

        def test_registers_offense_for_constants_without_receiver
          assert_offense(<<~RUBY)
            klass = constants.select { |c| c.name == "Foo" }
                    ^^^^^^^^^ #{error_message("constants")}
          RUBY
        end

        private

        def error_message(method_name)
          "Sorbet/ConstantsFromStrings: Don't use `#{method_name}`, it makes the code harder to understand, less editor-friendly, " \
            "and impossible to analyze. Replace `#{method_name}` with a case/when or a hash."
        end
      end
    end
  end
end
