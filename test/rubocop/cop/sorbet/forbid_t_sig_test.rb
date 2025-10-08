# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTSigTest < ::Minitest::Test
        def setup
          @cop = ForbidTSig.new
        end

        def test_adds_offense_when_extending_t_sig
          assert_offense(<<~RUBY)
            class Example
              extend T::Sig
              ^^^^^^^^^^^^^ Sorbet/ForbidTSig: Do not use `extend T::Sig`.
            end
          RUBY
        end

        def test_adds_offense_when_including_t_sig
          assert_offense(<<~RUBY)
            class Example
              include T::Sig
              ^^^^^^^^^^^^^^ Sorbet/ForbidTSig: Do not use `include T::Sig`.
            end
          RUBY
        end

        def test_adds_offense_when_extending_t_sig_in_module
          assert_offense(<<~RUBY)
            module Example
              extend T::Sig
              ^^^^^^^^^^^^^ Sorbet/ForbidTSig: Do not use `extend T::Sig`.
            end
          RUBY
        end

        def test_adds_offense_when_extending_t_sig_with_cbase
          assert_offense(<<~RUBY)
            class Example
              extend ::T::Sig
              ^^^^^^^^^^^^^^^ Sorbet/ForbidTSig: Do not use `extend T::Sig`.
            end
          RUBY
        end

        def test_no_offense_when_not_using_t_sig
          assert_no_offenses(<<~RUBY)
            class Example
            end
          RUBY
        end

        def test_no_offense_when_extending_other_modules
          assert_no_offenses(<<~RUBY)
            class Example
              extend ActiveSupport::Concern
            end
          RUBY
        end

        def test_no_offense_when_extending_t_helpers
          assert_no_offenses(<<~RUBY)
            class Example
              extend T::Helpers
            end
          RUBY
        end
      end
    end
  end
end
