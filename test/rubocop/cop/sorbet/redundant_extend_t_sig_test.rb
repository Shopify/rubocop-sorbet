# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class RedundantExtendTSigTest < ::Minitest::Test
        MSG = "Sorbet/RedundantExtendTSig: Do not redundantly `extend T::Sig` when it is already included in all modules."

        def setup
          @cop = RedundantExtendTSig.new
        end

        def test_registers_offense_when_using_extend_t_sig_in_module
          assert_offense(<<~RUBY)
            module M
              extend T::Sig
              ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            module M
            end
          RUBY
        end

        def test_registers_offense_when_using_extend_t_sig_in_class
          assert_offense(<<~RUBY)
            class C
              extend T::Sig
              ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class C
            end
          RUBY
        end

        def test_registers_offense_when_using_extend_t_sig_in_anonymous_module
          assert_offense(<<~RUBY)
            Module.new do
              extend T::Sig
              ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            Module.new do
            end
          RUBY
        end

        def test_registers_offense_when_using_extend_t_sig_in_anonymous_class
          assert_offense(<<~RUBY)
            Class.new do
              extend T::Sig
              ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            Class.new do
            end
          RUBY
        end

        def test_registers_offense_when_using_extend_t_sig_in_self_singleton_class
          assert_offense(<<~RUBY)
            class << self
              extend T::Sig
              ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class << self
            end
          RUBY
        end

        def test_registers_offense_when_using_extend_t_sig_in_arbitrary_singleton_class
          assert_offense(<<~RUBY)
            class << object
              extend T::Sig
              ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            class << object
            end
          RUBY
        end

        def test_registers_offense_when_using_extend_t_sig_in_module_with_other_contents
          assert_offense(<<~RUBY)
            module M
              extend SomethingElse
              extend T::Sig
              ^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            module M
              extend SomethingElse
            end
          RUBY
        end

        def test_registers_offense_when_using_extend_t_sig_on_its_own
          assert_offense(<<~RUBY)
            extend T::Sig
            ^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction("")
        end

        def test_registers_offense_when_using_extend_t_sig_fully_qualified
          assert_offense(<<~RUBY)
            extend ::T::Sig
            ^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction("")
        end

        def test_registers_offense_when_using_extend_t_sig_with_explicit_receiver
          assert_offense(<<~RUBY)
            some_module.extend T::Sig
            ^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction("")
        end

        def test_does_not_register_offense_when_extending_other_modules_in_t_namespace
          assert_no_offenses(<<~RUBY)
            module M
              extend T::Helpers
            end
          RUBY
        end
      end
    end
  end
end
