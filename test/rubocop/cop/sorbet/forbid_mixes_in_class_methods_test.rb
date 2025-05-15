# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidMixesInClassMethodsTest < ::Minitest::Test
        MSG = "Sorbet/ForbidMixesInClassMethods: #{ForbidMixesInClassMethods::MSG}"

        def setup
          @cop = ForbidMixesInClassMethods.new
        end

        def test_adds_offense_when_using_mixes_in_class_methods
          assert_offense(<<~RUBY)
            mixes_in_class_methods
            ^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

            mixes_in_class_methods(ClassMethods)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

            T::Helpers.mixes_in_class_methods(ClassMethods)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

            self.mixes_in_class_methods(ClassMethods)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

            foo = mixes_in_class_methods(ClassMethods)
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY
        end

        def test_does_not_add_offense_when_using_mixes_in_class_methods_on_another_class
          assert_no_offenses(<<~RUBY)
            T.mixes_in_class_methods(ClassMethods)
            Helpers.mixes_in_class_methods(ClassMethods)
            Foo.mixes_in_class_methods(ClassMethods)
          RUBY
        end
      end
    end
  end
end
