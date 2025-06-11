# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class ForbidRBSAbstractTest < ::Minitest::Test
          MSG = "Sorbet/ForbidRBSAbstract: Do not use `@abstract`."

          def setup
            @cop = ForbidRBSAbstract.new
          end

          def test_registers_offense_on_abstract_annotation_on_def_with_rbs_signature
            assert_offense(<<~RUBY)
              # @abstract
              ^^^^^^^^^^^ #{MSG}
              #: -> void
              def foo; end
            RUBY
          end

          def test_registers_offense_on_abstract_annotation_on_defs
            assert_offense(<<~RUBY)
              #: -> void
              # @abstract
              ^^^^^^^^^^^ #{MSG}
              def self.foo; end
            RUBY
          end

          def test_registers_offense_on_abstract_annotation_without_rbs_signature
            assert_no_offenses(<<~RUBY)
              # @abstract
              def foo; end

              # @abstract
              def self.foo; end
            RUBY
          end

          def test_does_not_register_offense_on_other_annotations
            assert_no_offenses(<<~RUBY)
              # @not_abstract
              #: -> void
              def foo; end
            RUBY
          end

          def test_does_not_register_offense_on_inexact_abstract_annotation
            assert_no_offenses(<<~RUBY)
              # @abstract: something
              #: -> void
              def foo; end
            RUBY
          end

          def test_does_not_register_offense_on_class_or_module_annotations
            assert_no_offenses(<<~RUBY)
              # @abstract
              #: [E]
              class Foo; end

              # @abstract
              #: [E]
              module Bar; end
            RUBY
          end

          def test_registers_offense_on_abstract_with_other_comments
            assert_offense(<<~RUBY)
              # some comment
              # @abstract
              ^^^^^^^^^^^ #{MSG}
              # some other comment
              #: -> void
              def foo; end
            RUBY
          end
        end
      end
    end
  end
end
