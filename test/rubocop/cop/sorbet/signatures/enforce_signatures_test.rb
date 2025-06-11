# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class EnforceSignaturesTest < ::Minitest::Test
          MSG = "Each method is required to have a signature."
          MSG_SIG = "Each method is required to have a sig block signature."

          def setup
            cop_config = cop_config({
              "Style" => "both",
            })
            @cop = target_cop.new(cop_config)
          end

          def test_makes_no_offense_if_top_level_method_has_signature
            assert_no_offenses(<<~RUBY)
              sig { void }
              def foo; end
            RUBY
          end

          def test_makes_no_offense_if_top_level_method_has_rbs_signature
            assert_no_offenses(<<~RUBY)
              #: -> void
              def foo; end
            RUBY
          end

          def test_makes_no_offense_if_top_level_method_has_final_signature
            assert_no_offenses(<<~RUBY)
              sig(:final) { void }
              def foo; end
            RUBY
          end

          def test_makes_offense_if_top_level_method_has_no_signature
            assert_offense(<<~RUBY)
              def foo; end
              ^^^^^^^^^^^^ #{MSG}
            RUBY
          end

          def test_does_not_check_signature_validity
            assert_no_offenses(<<~RUBY)
              sig { foo(bar).baz }
              def foo; end
            RUBY
          end

          def test_does_not_check_rbs_signature_validity
            assert_no_offenses(<<~RUBY)
              #: hello world
              def foo; end
            RUBY
          end

          def test_makes_no_offense_if_method_has_signature
            assert_no_offenses(<<~RUBY)
              class Foo
                sig { void }
                def foo1; end
              end
            RUBY
          end

          def test_makes_no_offense_if_method_has_rbs_signature
            assert_no_offenses(<<~RUBY)
              class Foo
                #: -> void
                def foo1; end
              end
            RUBY
          end

          def test_makes_offense_if_method_has_no_signature
            assert_offense(<<~RUBY)
              class Foo
                def foo; end
                ^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_registers_no_offenses_on_signature_overloads
            assert_no_offenses(<<~RUBY)
              class Foo
                sig { void }
                sig { void }
                sig { void }
                sig { void }
                sig { void }
                def foo; end
              end

              sig { void }
              sig { void }
              def foo; end
            RUBY
          end

          def test_registers_offenses_even_when_methods_with_same_name_have_sigs_in_other_scopes
            assert_offense(<<~RUBY)
              module Foo
                sig { void }
              end

              class Bar
                def foo; end
                ^^^^^^^^^^^^ #{MSG}

                sig { void }
              end

              def foo; end
              ^^^^^^^^^^^^ #{MSG}

              class Baz
                sig { void }
                def foo; end

                def baz; end
                ^^^^^^^^^^^^ #{MSG}
              end

              foo do
                sig { void }
                def foo; end

                def baz; end
                ^^^^^^^^^^^^ #{MSG}
              end

              foo do
                sig { void }
              end

              foo do
                def foo; end
                ^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_registers_offenses_even_when_methods_with_same_name_have_rbs_sigs_in_other_scopes
            assert_offense(<<~RUBY)
              module Foo
                #: -> void
              end

              class Bar
                def foo; end
                ^^^^^^^^^^^^ #{MSG}

                #: -> void
              end

              def foo; end
              ^^^^^^^^^^^^ #{MSG}

              class Baz
                #: -> void
                def foo; end

                def baz; end
                ^^^^^^^^^^^^ #{MSG}
              end

              foo do
                #: -> void
                def foo; end

                def baz; end
                ^^^^^^^^^^^^ #{MSG}
              end

              foo do
                #: -> void
              end

              foo do
                def foo; end
                ^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_makes_no_offense_if_singleton_method_has_signature
            assert_no_offenses(<<~RUBY)
              class Foo
                sig { void }
                def self.foo1; end
              end
            RUBY
          end

          def test_makes_no_offense_if_singleton_method_has_rbs_signature
            assert_no_offenses(<<~RUBY)
              class Foo
                #: -> void
                def self.foo1; end
              end
            RUBY
          end

          def test_makes_offense_if_singleton_method_has_no_signature
            assert_offense(<<~RUBY)
              class Foo
                def self.foo; end
                ^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_makes_no_offense_if_accessor_has_signature
            assert_no_offenses(<<~RUBY)
              class Foo
                sig { returns(String) }
                attr_reader :foo
                sig { params(bar: String).void }
                attr_writer :bar
                sig { params(baz: String).returns(String) }
                attr_accessor :baz
              end
            RUBY
          end

          def test_makes_no_offense_if_accessor_has_rbs_signature
            assert_no_offenses(<<~RUBY)
              class Foo
                #: -> String
                attr_reader :foo
                #: (String) -> void
                attr_writer :bar
                #: (String) -> String
                attr_accessor :baz
              end
            RUBY
          end

          def test_makes_offense_if_accessor_has_no_signature
            assert_offense(<<~RUBY)
              class Foo
                attr_reader :foo
                ^^^^^^^^^^^^^^^^ #{MSG}
                attr_writer :bar
                ^^^^^^^^^^^^^^^^ #{MSG}
                attr_accessor :baz
                ^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_makes_no_offense_if_signature_is_declared_with_t_sig_without_runtime_sig
            assert_no_offenses(<<~RUBY)
              class Foo
                T::Sig::WithoutRuntime.sig { void }
                def foo; end
              end
            RUBY
          end

          def test_makes_no_offense_if_signature_is_declared_with_t_sig_sig
            assert_no_offenses(<<~RUBY)
              class Foo
                T::Sig.sig { void }
                def foo; end
              end
            RUBY
          end

          def test_makes_offense_if_signature_on_unknown_receiver
            assert_offense(<<~RUBY)
              class Foo
                T::Sig::WithRuntime.sig { void }
                def foo; end
                ^^^^^^^^^^^^ #{MSG}

                T::SomeSig.sig { void }
                def foo; end
                ^^^^^^^^^^^^ #{MSG}

                Sig.sig { void }
                def foo; end
                ^^^^^^^^^^^^ #{MSG}
              end
            RUBY
          end

          def test_makes_no_offense_if_method_has_comment_separating_rbs_signature
            assert_no_offenses(<<~RUBY)
              # before
              #: -> void
              # after
              def foo; end
            RUBY
          end

          def test_makes_offense_if_method_has_blank_line_separating_rbs_signature
            assert_offense(<<~RUBY)
              #: -> void

              def foo; end
              ^^^^^^^^^^^^ #{MSG}
            RUBY
          end

          def test_does_not_check_signature_for_accessors
            assert_no_offenses(<<~RUBY)
              class Foo
                sig { void }
                attr_reader :foo, :bar
              end
            RUBY
          end

          def test_does_not_check_rbs_signature_for_accessors
            assert_no_offenses(<<~RUBY)
              class Foo
                #: -> void
                attr_reader :foo, :bar
              end
            RUBY
          end

          def test_supports_visibility_modifiers
            assert_no_offenses(<<~RUBY)
              sig { void }
              private def foo; end

              sig { void }
              public def foo; end

              sig { void }
              protected def foo; end

              sig { void }
              foo bar baz def foo; end
            RUBY
          end

          def test_supports_visibility_modifiers_for_rbs_signatures
            assert_no_offenses(<<~RUBY)
              #: -> void
              private def foo; end

              #: -> void
              public def foo; end

              #: -> void
              protected def foo; end

              #: -> void
              foo bar baz def foo; end
            RUBY
          end

          def test_autocorrects_methods_by_adding_signature_stubs
            assert_offense(<<~RUBY)
              def foo; end
              ^^^^^^^^^^^^ #{MSG}
              def bar(a, b = 2, c: Foo.new); end
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def baz(&blk); end
              ^^^^^^^^^^^^^^^^^^ #{MSG}
              def self.foo(a, b, &c); end
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def self.bar(a, *b, **c); end
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def self.baz(a:); end
              ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            RUBY

            assert_correction(<<~RUBY)
              sig { returns(T.untyped) }
              def foo; end
              sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
              def bar(a, b = 2, c: Foo.new); end
              sig { params(blk: T.untyped).returns(T.untyped) }
              def baz(&blk); end
              sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
              def self.foo(a, b, &c); end
              sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped) }
              def self.bar(a, *b, **c); end
              sig { params(a: T.untyped).returns(T.untyped) }
              def self.baz(a:); end
            RUBY
          end

          def test_autocorrects_accessors_by_adding_signature_stubs
            assert_offense(<<~RUBY)
              class Foo
                attr_reader :foo
                ^^^^^^^^^^^^^^^^ #{MSG}
                attr_writer :bar
                ^^^^^^^^^^^^^^^^ #{MSG}
                attr_accessor :baz
                ^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY

            assert_correction(<<~RUBY)
              class Foo
                sig { returns(T.untyped) }
                attr_reader :foo
                sig { params(bar: T.untyped).void }
                attr_writer :bar
                sig { params(baz: T.untyped).returns(T.untyped) }
                attr_accessor :baz
              end
            RUBY
          end

          def test_makes_offense_if_allow_rbs_false
            @cop = target_cop.new(cop_config({
              "Style" => "sig",
            }))
            assert_offense(<<~RUBY)
              #: -> void
              def foo; end
              ^^^^^^^^^^^^ #{MSG_SIG}
            RUBY
          end

          def test_autocorrects_with_custom_values
            @cop = target_cop.new(cop_config({
              "Style" => "both",
              "ParameterTypePlaceholder" => "PARAM",
              "ReturnTypePlaceholder" => "RET",
            }))

            assert_offense(<<~RUBY)
              def foo; end
              ^^^^^^^^^^^^ #{MSG}
              def bar(a, b = 2, c: Foo.new); end
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              def baz(&blk); end
              ^^^^^^^^^^^^^^^^^^ #{MSG}

              class Foo
                def foo
                ^^^^^^^ #{MSG}
                end

                def bar(a, b, c)
                ^^^^^^^^^^^^^^^^ #{MSG}
                end
              end
            RUBY
            assert_correction(<<~RUBY)
              sig { returns(RET) }
              def foo; end
              sig { params(a: PARAM, b: PARAM, c: PARAM).returns(RET) }
              def bar(a, b = 2, c: Foo.new); end
              sig { params(blk: PARAM).returns(RET) }
              def baz(&blk); end

              class Foo
                sig { returns(RET) }
                def foo
                end

                sig { params(a: PARAM, b: PARAM, c: PARAM).returns(RET) }
                def bar(a, b, c)
                end
              end
            RUBY
          end

          def test_autocorrects_accessors_with_custom_values
            @cop = target_cop.new(cop_config({
              "Style" => "both",
              "ParameterTypePlaceholder" => "PARAM",
              "ReturnTypePlaceholder" => "RET",
            }))
            assert_offense(<<~RUBY)
              class Foo
                attr_reader :foo
                ^^^^^^^^^^^^^^^^ #{MSG}
                attr_writer :bar
                ^^^^^^^^^^^^^^^^ #{MSG}
                attr_accessor :baz
                ^^^^^^^^^^^^^^^^^^ #{MSG}
              end
            RUBY
            assert_correction(<<~RUBY)
              class Foo
                sig { returns(RET) }
                attr_reader :foo
                sig { params(bar: PARAM).void }
                attr_writer :bar
                sig { params(baz: PARAM).returns(RET) }
                attr_accessor :baz
              end
            RUBY
          end

          def test_enforce_rbs_accepts_rbs_signatures
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_no_offenses(<<~RUBY)
              #: -> void
              def foo; end
            RUBY
          end

          def test_enforce_rbs_requires_rbs_signature
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              def foo; end
              ^^^^^^^^^^^^ Each method is required to have an RBS signature.
            RUBY
          end

          def test_enforce_rbs_with_class_methods
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              class Foo
                sig { void }
                ^^^^^^^^^^^^ Use RBS signature comments rather than sig blocks.
                def foo; end

                #: -> void
                def bar; end

                def baz; end
                ^^^^^^^^^^^^ Each method is required to have an RBS signature.
              end
            RUBY
          end

          def test_enforce_rbs_with_singleton_methods
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              class Foo
                sig { void }
                ^^^^^^^^^^^^ Use RBS signature comments rather than sig blocks.
                def self.foo; end

                #: -> void
                def self.bar; end
              end
            RUBY
          end

          def test_enforce_rbs_with_accessors
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              class Foo
                sig { returns(String) }
                ^^^^^^^^^^^^^^^^^^^^^^^ Use RBS signature comments rather than sig blocks.
                attr_reader :foo

                #: -> String
                attr_reader :bar

                attr_writer :baz
                ^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
              end
            RUBY
          end

          def test_enforce_rbs_takes_precedence_over_allow_rbs
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              sig { void }
              ^^^^^^^^^^^^ Use RBS signature comments rather than sig blocks.
              def foo; end
            RUBY
          end

          def test_enforce_rbs_autocorrects_missing_signatures
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              def foo; end
              ^^^^^^^^^^^^ Each method is required to have an RBS signature.
              def bar(a, b = 2, c: Foo.new); end
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
              def baz(&blk); end
              ^^^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
              def self.foo(a, b, &c); end
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
              def self.bar(a, *b, **c); end
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
              def self.baz(a:); end
              ^^^^^^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
            RUBY

            assert_correction(<<~RUBY)
              #: () -> untyped
              def foo; end
              #: (untyped, untyped, untyped) -> untyped
              def bar(a, b = 2, c: Foo.new); end
              #: (untyped) -> untyped
              def baz(&blk); end
              #: (untyped, untyped, untyped) -> untyped
              def self.foo(a, b, &c); end
              #: (untyped, untyped, untyped) -> untyped
              def self.bar(a, *b, **c); end
              #: (untyped) -> untyped
              def self.baz(a:); end
            RUBY
          end

          def test_enforce_rbs_autocorrects_accessors
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              class Foo
                attr_reader :foo
                ^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
                attr_writer :bar
                ^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
                attr_accessor :baz
                ^^^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
              end
            RUBY

            assert_correction(<<~RUBY)
              class Foo
                #: () -> untyped
                attr_reader :foo
                #: (untyped) -> void
                attr_writer :bar
                #: (untyped) -> untyped
                attr_accessor :baz
              end
            RUBY
          end

          def test_enforce_rbs_autocorrects_with_proper_indentation
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              class Foo
                def foo
                ^^^^^^^ Each method is required to have an RBS signature.
                end

                def bar(a, b, c)
                ^^^^^^^^^^^^^^^^ Each method is required to have an RBS signature.
                end
              end
            RUBY

            assert_correction(<<~RUBY)
              class Foo
                #: () -> untyped
                def foo
                end

                #: (untyped, untyped, untyped) -> untyped
                def bar(a, b, c)
                end
              end
            RUBY
          end

          def test_enforce_rbs_does_not_autocorrect_sig_signatures
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              sig { void }
              ^^^^^^^^^^^^ Use RBS signature comments rather than sig blocks.
              def foo; end
            RUBY

            assert_no_corrections
          end

          def test_enforce_rbs_rejects_sig_signatures
            @cop = target_cop.new(cop_config({
              "Style" => "rbs",
            }))

            assert_offense(<<~RUBY)
              sig { void }
              ^^^^^^^^^^^^ Use RBS signature comments rather than sig blocks.
              def foo; end
            RUBY
          end

          def test_allow_rbs_deprecation_warning
            config = RuboCop::Config.new({
              "AllCops" => { "TargetRubyVersion" => 2.7 },
              "Sorbet/EnforceSignatures" => {
                "Enabled" => true,
                "AllowRBS" => true,
              },
            })
            @cop = target_cop.new(config)

            assert_no_offenses(<<~RUBY)
              sig { void }
              def foo; end

              #: -> void
              def bar; end
            RUBY
          end

          def test_allow_rbs_with_style_uses_style
            @cop = target_cop.new(cop_config({
              "AllowRBS" => true,
              "Style" => "sig",
            }))

            assert_offense(<<~RUBY)
              #: -> void
              def foo; end
              ^^^^^^^^^^^^ #{MSG_SIG}
            RUBY
          end

          private

          def target_cop
            EnforceSignatures
          end
        end
      end
    end
  end
end
