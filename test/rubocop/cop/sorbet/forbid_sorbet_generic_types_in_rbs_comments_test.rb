# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidSorbetGenericTypesInRBSCommentsTest < ::Minitest::Test
        MSG = "Sorbet/ForbidSorbetGenericTypesInRBSComments: " \
          "Use `%<rbs_type>s` instead of Sorbet's `%<sorbet_type>s` in RBS comments."

        def setup
          @cop = ForbidSorbetGenericTypesInRBSComments.new
        end

        def test_registers_offense_when_sorbet_generic_types_are_used_in_rbs_comments
          assert_offense(<<~RUBY)
            #: (T::Array[String],
                ^^^^^^^^ #{format(MSG, rbs_type: "Array", sorbet_type: "T::Array")}
            #|   T::Enumerator::Chain[String],
                 ^^^^^^^^^^^^^^^^^^^^ #{format(MSG, rbs_type: "Enumerator::Chain", sorbet_type: "T::Enumerator::Chain")}
            #|   ::T::Enumerator::Lazy[String],
                 ^^^^^^^^^^^^^^^^^^^^^ #{format(MSG, rbs_type: "Enumerator::Lazy", sorbet_type: "::T::Enumerator::Lazy")}
            #|   ::T::Class[String],
                 ^^^^^^^^^^ #{format(MSG, rbs_type: "Class", sorbet_type: "::T::Class")}
            #|   T::Enumerable[String],
                 ^^^^^^^^^^^^^ #{format(MSG, rbs_type: "Enumerable", sorbet_type: "T::Enumerable")}
            #|   T::Enumerator[String]
                 ^^^^^^^^^^^^^ #{format(MSG, rbs_type: "Enumerator", sorbet_type: "T::Enumerator")}
            #|) -> T::Hash[::T::Module[String], T::Set[T::Range[Integer]]]
                   ^^^^^^^ #{format(MSG, rbs_type: "Hash", sorbet_type: "T::Hash")}
                           ^^^^^^^^^^^ #{format(MSG, rbs_type: "Module", sorbet_type: "::T::Module")}
                                                ^^^^^^ #{format(MSG, rbs_type: "Set", sorbet_type: "T::Set")}
                                                       ^^^^^^^^ #{format(MSG, rbs_type: "Range", sorbet_type: "T::Range")}
          RUBY
          assert_correction(<<~RUBY)
            #: (Array[String],
            #|   Enumerator::Chain[String],
            #|   Enumerator::Lazy[String],
            #|   Class[String],
            #|   Enumerable[String],
            #|   Enumerator[String]
            #|) -> Hash[Module[String], Set[Range[Integer]]]
          RUBY
        end

        def test_registers_offense_when_sorbet_generic_type_is_used_in_inline_comment
          assert_offense(<<~RUBY)
            values = [] #: T::Array[String]
                           ^^^^^^^^ #{format(MSG, rbs_type: "Array", sorbet_type: "T::Array")}
          RUBY
          assert_correction(<<~RUBY)
            values = [] #: Array[String]
          RUBY
        end

        def test_registers_offense_when_sorbet_generic_type_is_used_in_type_alias
          assert_offense(<<~RUBY)
            #: type time_param = T::Range[Time]
                                 ^^^^^^^^ #{format(MSG, rbs_type: "Range", sorbet_type: "T::Range")}
          RUBY
          assert_correction(<<~RUBY)
            #: type time_param = Range[Time]
          RUBY
        end

        def test_registers_offense_when_sorbet_generic_type_is_used_in_type_assertion
          assert_offense(<<~RUBY)
            values = result #: as T::Array[String]
                                  ^^^^^^^^ #{format(MSG, rbs_type: "Array", sorbet_type: "T::Array")}
          RUBY
          assert_correction(<<~RUBY)
            values = result #: as Array[String]
          RUBY
        end

        def test_does_not_register_offense_when_sorbet_generic_types_are_used_outside_rbs_comments
          assert_no_offenses(<<~RUBY)
            sig { returns(T::Array[String]) }
          RUBY
        end

        def test_does_not_register_offense_on_non_generic_types
          assert_no_offenses(<<~RUBY)
            #: () -> T::Array
            #: () -> SomeT::Array[String]
            #: () -> Foo::T::Array[String]
          RUBY
        end
      end
    end
  end
end
