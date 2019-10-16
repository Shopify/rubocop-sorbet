# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/rubocop/cop/sorbet/signatures/enforce_signatures'

RSpec.describe(RuboCop::Cop::Sorbet::EnforceSignatures, :config) do
  subject(:cop) { described_class.new(config) }

  describe('require a signature for each method') do
    it 'makes no offense if a top-level method has a signature' do
      expect_no_offenses(<<~RUBY)
        sig { void }
        def foo; end
      RUBY
    end

    it 'makes offense if a top-level method has no signature' do
      expect_offense(<<~RUBY)
        def foo; end
        ^^^^^^^^^^^^ Each method is required to have a signature.
      RUBY
    end

    it 'does not check signature validity' do # Validity will be checked by Sorbet
      expect_no_offenses(<<~RUBY)
        sig { foo(bar).baz }
        def foo; end
      RUBY
    end

    it 'makes no offense if a method has a signature' do
      expect_no_offenses(<<~RUBY)
        class Foo
          sig { void }
          def foo1; end
        end
      RUBY
    end

    it 'makes offense if a method has no signature' do
      expect_offense(<<~RUBY)
        class Foo
          def foo; end
          ^^^^^^^^^^^^ Each method is required to have a signature.
        end
      RUBY
    end

    it 'makes no offense if a singleton method has a signature' do
      expect_no_offenses(<<~RUBY)
        class Foo
          sig { void }
          def self.foo1; end
        end
      RUBY
    end

    it 'makes offense if a singleton method has no signature' do
      expect_offense(<<~RUBY)
        class Foo
          def self.foo; end
          ^^^^^^^^^^^^^^^^^ Each method is required to have a signature.
        end
      RUBY
    end

    it 'makes no offense if an accessor has a signature' do
      expect_no_offenses(<<~RUBY)
        class Foo
          sig { returns(String) }
          attr_reader :foo
          sig { params(bar: String).void }
          attr_writer :bar
          sig { params(bar: String).returns(String) }
          attr_accessor :baz
        end
      RUBY
    end

    it 'makes offense if an accessor has no signature' do
      expect_offense(<<~RUBY)
        class Foo
          attr_reader :foo
          ^^^^^^^^^^^^^^^^ Each method is required to have a signature.
          attr_writer :bar
          ^^^^^^^^^^^^^^^^ Each method is required to have a signature.
          attr_accessor :baz
          ^^^^^^^^^^^^^^^^^^ Each method is required to have a signature.
        end
      RUBY
    end

    it 'does not check the signature for accessors' do # Validity will be checked by Sorbet
      expect_no_offenses(<<~RUBY)
        class Foo
          sig { void }
          attr_reader :foo, :bar
        end
      RUBY
    end

    shared_examples_for('autocorrect with config') do
      it('autocorrects methods by adding signature stubs') do
        expect(
          autocorrect_source(<<~RUBY)
            def foo; end
            def bar(a, b = 2, c: Foo.new); end
            def baz(&blk); end
            def self.foo(a, b, &c); end
            def self.bar(a, *b, **c); end
            def self.baz(a:); end
          RUBY
        ).to(eq(<<~RUBY))
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

      it('autocorrects accessors by adding signature stubs') do
        expect(
          autocorrect_source(<<~RUBY)
            class Foo
              attr_reader :foo
              attr_writer :bar
              attr_accessor :baz
            end
          RUBY
        ).to(eq(<<~RUBY))
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
    end

    describe('autocorrect') do
      it_should_behave_like 'autocorrect with config'
    end

    describe('autocorrect with default values') do
      let(:cop_config) do
        {
          'Enabled' => true,
          'ParameterTypePlaceholder' => 'T.untyped',
          'ReturnTypePlaceholder' => 'T.untyped',
        }
      end
      it_should_behave_like 'autocorrect with config'
    end

    describe('autocorrect with custom values') do
      let(:cop_config) do
        {
          'Enabled' => true,
          'ParameterTypePlaceholder' => 'PARAM',
          'ReturnTypePlaceholder' => 'RET',
        }
      end

      it('autocorrects methods by adding signature stubs') do
        expect(
          autocorrect_source(<<~RUBY)
            def foo; end
            def bar(a, b = 2, c: Foo.new); end
            def baz(&blk); end

            class Foo
              def foo
              end

              def bar(a, b, c)
              end
            end
          RUBY
        ).to(eq(<<~RUBY))
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

      it('autocorrects accessors by adding signature stubs') do
        expect(
          autocorrect_source(<<~RUBY)
            class Foo
              attr_reader :foo
              attr_writer :bar
              attr_accessor :baz
            end
          RUBY
        ).to(eq(<<~RUBY))
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
    end
  end
end
