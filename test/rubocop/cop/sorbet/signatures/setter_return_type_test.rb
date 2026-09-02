# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class SetterReturnTypeTest < ::Minitest::Test
          MSG = "Setter methods must declare a `void` return type."

          def setup
            @cop = target_cop.new(cop_config)
          end

          def target_cop
            SetterReturnType
          end

          def test_offense_for_sig_with_returns
            assert_offense(<<~RUBY)
              sig { params(name: String).returns(String) }
                                         ^^^^^^^^^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              sig { params(name: String).void }
              def name=(name); end
            RUBY
          end

          def test_offense_for_singleton_setter_with_returns
            assert_offense(<<~RUBY)
              sig { params(name: String).returns(String) }
                                         ^^^^^^^^^^^^^^^ #{MSG}
              def self.name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              sig { params(name: String).void }
              def self.name=(name); end
            RUBY
          end

          def test_offense_for_index_setter_with_returns
            assert_offense(<<~RUBY)
              sig { params(key: Symbol, value: String).returns(String) }
                                                       ^^^^^^^^^^^^^^^ #{MSG}
              def []=(key, value); end
            RUBY
            assert_correction(<<~RUBY)
              sig { params(key: Symbol, value: String).void }
              def []=(key, value); end
            RUBY
          end

          def test_offense_for_each_overload_sig_with_returns
            assert_offense(<<~RUBY)
              sig { params(name: String).returns(String) }
                                         ^^^^^^^^^^^^^^^ #{MSG}
              sig { params(name: Integer).returns(Integer) }
                                          ^^^^^^^^^^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              sig { params(name: String).void }
              sig { params(name: Integer).void }
              def name=(name); end
            RUBY
          end

          def test_offense_for_sig_with_returns_t_proc_void
            assert_offense(<<~RUBY)
              sig { params(name: String).returns(T.proc.void) }
                                         ^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              sig { params(name: String).void }
              def name=(name); end
            RUBY
          end

          def test_offense_for_multiline_sig_with_returns
            assert_offense(<<~RUBY)
              sig do
                params(name: String)
                  .returns(String)
                   ^^^^^^^^^^^^^^^ #{MSG}
              end
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              sig do
                params(name: String)
                  .void
              end
              def name=(name); end
            RUBY
          end

          def test_offense_for_final_sig_with_returns
            assert_offense(<<~RUBY)
              sig(:final) { params(name: String).returns(String) }
                                                 ^^^^^^^^^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              sig(:final) { params(name: String).void }
              def name=(name); end
            RUBY
          end

          def test_offense_for_private_def_setter_with_returns
            assert_offense(<<~RUBY)
              sig { params(name: String).returns(String) }
                                         ^^^^^^^^^^^^^^^ #{MSG}
              private def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              sig { params(name: String).void }
              private def name=(name); end
            RUBY
          end

          def test_offense_for_sig_with_returns_and_trailing_modifier
            assert_offense(<<~RUBY)
              sig { params(name: String).returns(String).soft }
                                         ^^^^^^^^^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              sig { params(name: String).void.soft }
              def name=(name); end
            RUBY
          end

          def test_offense_for_each_of_two_identical_setter_defs
            assert_offense(<<~RUBY)
              sig { params(name: String).returns(String) }
                                         ^^^^^^^^^^^^^^^ #{MSG}
              def name=(name); end

              sig { params(name: String).returns(String) }
                                         ^^^^^^^^^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              sig { params(name: String).void }
              def name=(name); end

              sig { params(name: String).void }
              def name=(name); end
            RUBY
          end

          def test_offense_for_rbs_with_non_void_return
            assert_offense(<<~RUBY)
              #: (String) -> String
                             ^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (String) -> void
              def name=(name); end
            RUBY
          end

          def test_offense_for_rbs_with_non_void_return_private_def
            assert_offense(<<~RUBY)
              #: (String) -> String
                             ^^^^^^ #{MSG}
              private def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (String) -> void
              private def name=(name); end
            RUBY
          end

          def test_offense_for_multiline_rbs_with_non_void_return
            assert_offense(<<~RUBY)
              #: (
              #| String name
              #| ) -> String
                      ^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (
              #| String name
              #| ) -> void
              def name=(name); end
            RUBY
          end

          def test_offense_for_multiline_rbs_class_method
            assert_offense(<<~RUBY)
              #: (
              #| String name
              #| ) -> String
                      ^^^^^^ #{MSG}
              def self.name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (
              #| String name
              #| ) -> void
              def self.name=(name); end
            RUBY
          end

          def test_offense_for_rbs_overload_mixed_void_and_non_void
            assert_offense(<<~RUBY)
              #: (String) -> void
              #: (Integer) -> Integer
                              ^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (String) -> void
              #: (Integer) -> void
              def name=(name); end
            RUBY
          end

          def test_offense_for_rbs_overload_both_non_void
            assert_offense(<<~RUBY)
              #: (String) -> String
                             ^^^^^^ #{MSG}
              #: (Integer) -> Integer
                              ^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (String) -> void
              #: (Integer) -> void
              def name=(name); end
            RUBY
          end

          def test_offense_for_multiline_rbs_overload_mixed
            assert_offense(<<~RUBY)
              #: (String) -> void
              #: (
              #| Integer name
              #| ) -> Integer
                      ^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (String) -> void
              #: (
              #| Integer name
              #| ) -> void
              def name=(name); end
            RUBY
          end

          def test_offense_for_rbs_proc_return
            assert_offense(<<~RUBY)
              #: (String) -> ^(Integer) -> void
                             ^^^^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (String) -> void
              def name=(name); end
            RUBY
          end

          def test_offense_for_rbs_block_return
            assert_offense(<<~RUBY)
              #: () { (?) -> untyped } -> String
                                          ^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: () { (?) -> untyped } -> void
              def name=(name); end
            RUBY
          end

          def test_offense_for_rbs_return_on_next_line
            assert_offense(<<~RUBY)
              #: (String) ->
              #| String
                 ^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (String) ->
              #| void
              def name=(name); end
            RUBY
          end

          def test_offense_for_rbs_multiline_union_return
            assert_offense(<<~RUBY)
              #: (String) ->
              #| (Integer | String)
                  ^^^^^^^ #{MSG}
              def name=(name); end
            RUBY
            assert_correction(<<~RUBY)
              #: (String) ->
              #| (void)
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_rbs_unparenthesized_union_return
            assert_no_offenses(<<~RUBY)
              #: (String) -> Integer | String
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_sig_with_void
            assert_no_offenses(<<~RUBY)
              sig { params(name: String).void }
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_sig_with_void_after_returns_chain
            assert_no_offenses(<<~RUBY)
              sig { params(name: String).returns(String).void }
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_incomplete_sig_without_return
            assert_no_offenses(<<~RUBY)
              sig { params(name: String) }
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_multiline_sig_with_void
            assert_no_offenses(<<~RUBY)
              sig do
                params(name: String).void
              end
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_non_setter_method_with_returns
            assert_no_offenses(<<~RUBY)
              sig { params(name: String).returns(String) }
              def name(name); end
            RUBY
          end

          def test_no_offense_for_operator_methods_ending_with_equals
            assert_no_offenses(<<~RUBY)
              sig { params(other: Object).returns(T::Boolean) }
              def ==(other); end

              sig { params(other: Object).returns(T::Boolean) }
              def !=(other); end

              sig { params(other: Object).returns(T::Boolean) }
              def <=(other); end

              sig { params(other: Object).returns(T::Boolean) }
              def >=(other); end

              sig { params(other: Object).returns(T::Boolean) }
              def ===(other); end
            RUBY
          end

          def test_offense_for_unicode_setter_with_returns
            assert_offense(<<~RUBY)
              sig { params(value: String).returns(String) }
                                          ^^^^^^^^^^^^^^^ #{MSG}
              def 名前=(value); end
            RUBY
            assert_correction(<<~RUBY)
              sig { params(value: String).void }
              def 名前=(value); end
            RUBY
          end

          def test_does_not_inherit_sig_across_intervening_method
            assert_no_offenses(<<~RUBY)
              sig { params(x: Integer).returns(Integer) }
              def foo(x); end
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_private_def_setter_with_void
            assert_no_offenses(<<~RUBY)
              sig { params(name: String).void }
              private def name=(name); end
            RUBY
          end

          def test_no_offense_for_rbs_with_void_return
            assert_no_offenses(<<~RUBY)
              #: (String) -> void
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_rbs_with_void_return_protected_def
            assert_no_offenses(<<~RUBY)
              #: (String) -> void
              protected def name=(name); end
            RUBY
          end

          def test_no_offense_for_non_rbs_comment_before_setter
            assert_no_offenses(<<~RUBY)
              # (String) -> String
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_rbs_block_void_return
            assert_no_offenses(<<~RUBY)
              #: () { (?) -> untyped } -> void
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_rbs_return_void_on_next_line
            assert_no_offenses(<<~RUBY)
              #: (String) ->
              #| void
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_rbs_overload_both_void
            assert_no_offenses(<<~RUBY)
              #: (String) -> void
              #: (Integer) -> void
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_rbs_without_return_type
            assert_no_offenses(<<~RUBY)
              #: (String)
              def name=(name); end
            RUBY
          end

          def test_no_offense_for_setter_without_signature
            assert_no_offenses(<<~RUBY)
              def name=(name); end
            RUBY
          end
        end
      end
    end
  end
end
