# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ImplicitConversionMethodTest < ::Minitest::Test
        MSG = "Sorbet/ImplicitConversionMethod: Avoid implicit conversion methods, as Sorbet does not support them. " \
          "Explicity convert to the desired type instead."

        def setup
          @cop = ImplicitConversionMethod.new
        end

        def test_adds_offense_when_defining_implicit_conversion_instance_method
          assert_offense(<<~RUBY)
            def to_ary
            ^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_adds_offense_when_defining_implicit_conversion_class_method
          assert_offense(<<~RUBY)
            def self.to_int
            ^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_does_not_add_offense_when_method_arguments_exist
          assert_no_offenses(<<~RUBY)
            def to_int(foo)
            end
          RUBY
        end

        def test_adds_offense_when_declaring_an_implicit_conversion_method_via_alias
          assert_offense(<<~RUBY)
            alias to_str to_s
                  ^^^^^^ #{MSG}
          RUBY
        end

        def test_adds_offense_when_declaring_an_implicit_conversion_method_via_alias_method
          assert_offense(<<~RUBY)
            alias_method :to_hash, :to_h
                         ^^^^^^^^ #{MSG}
          RUBY
        end
      end
    end
  end
end
