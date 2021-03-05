# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(RuboCop::Cop::Sorbet::OneAncestorPerLine, :config) do
  subject(:cop) { described_class.new(config) }

  describe('no offences') do
    it 'adds no offences when there are no requires_ancestor calls' do
      expect_no_offenses(<<~RUBY)
        module MyModule
          def hello_world; end
        end
      RUBY
    end

    it 'adds no offences when just one ancestor is required per line' do
      expect_no_offenses(<<~RUBY)
        module MyModule
          requires_ancestor Kernel
          requires_ancestor Minitest::Assertions
          requires_ancestor Foo::Bar
        end
      RUBY
    end

    it 'adds no offences when an abstract class does not require any ancestors' do
      expect_no_offenses(<<~RUBY)
        class MyClass
          extend T::Sig
          extend T::Helpers
          abstract!

          sig {abstract.void}
          def self.foo; end
        end
      RUBY
    end

    it 'adds no offences when an abstract class has just one required ancestor per line' do
      expect_no_offenses(<<~RUBY)
        class MyClass
          extend T::Sig
          extend T::Helpers
          requires_ancestor Kernel
          requires_ancestor Minitest::Assertions
          requires_ancestor Foo::Bar

          abstract!

          sig {abstract.void}
          def self.foo; end
        end
      RUBY
    end
  end

  describe('offenses') do
    it 'adds offences when more than one ancestor is required on a line' do
      expect_offense(<<~RUBY)
        module MyModule
          requires_ancestor Kernel, Minitest::Assertions, SomeOtherModule, Foo::Bar
                                    ^^^^^^^^^^^^^^^^^^^^ Cannot require more than one ancestor per line
        end
      RUBY
    end

    it 'adds offences when a number of ancestors are formatted across multiple lines' do
      expect_offense(<<~RUBY)
        module MyModule
          requires_ancestor Kernel, Minitest::Assertions,
                                    ^^^^^^^^^^^^^^^^^^^^ Cannot require more than one ancestor per line
            SomeOtherModule, Foo::Bar
        end
      RUBY
    end

    it 'adds offences to abstract classes that use more than one ancestor per line' do
      expect_offense(<<~RUBY)
        class MyClass
          extend T::Sig
          extend T::Helpers
          requires_ancestor Kernel, Minitest::Assertions, Foo::Bar
                                    ^^^^^^^^^^^^^^^^^^^^ Cannot require more than one ancestor per line
          abstract!

          sig {abstract.void}
          def self.foo; end
        end
      RUBY
    end

    it 'adds an offence to a module inside a not-abstract class' do
      expect_offense(<<~RUBY)
        class Foo
          # not abstract

          module Bar
            requires_ancestor Kernel, Minitest::Assertions
                                      ^^^^^^^^^^^^^^^^^^^^ Cannot require more than one ancestor per line
          end
        end
      RUBY
    end

    it 'adds an offence to a module inside a not-abstract class' do
      expect_offense(<<~RUBY)
        class Foo
          extend T::Helpers

          abstract!

          module Bar
            requires_ancestor Kernel, Minitest::Assertions
                                      ^^^^^^^^^^^^^^^^^^^^ Cannot require more than one ancestor per line
          end
        end
      RUBY
    end
  end

  describe('Autocorrect') do
    it 'autocorrects the source to have requires_ancestor only call one ancestor per line' do
      source = <<~RUBY
        module MyModule
          requires_ancestor Kernel, Minitest::Assertions, SomeOtherModule, Foo::Bar
        end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          module MyModule
            requires_ancestor Kernel
            requires_ancestor Minitest::Assertions
            requires_ancestor SomeOtherModule
            requires_ancestor Foo::Bar
          end
        RUBY
    end

    it 'autocorrects when a large number of calls are formatted across multiple lines' do
      source = <<~RUBY
        module MyModule
          requires_ancestor Kernel, Minitest::Assertions,
            SomeOtherModule, Foo::Bar
        end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          module MyModule
            requires_ancestor Kernel
            requires_ancestor Minitest::Assertions
            requires_ancestor SomeOtherModule
            requires_ancestor Foo::Bar
          end
        RUBY
    end

    it 'does not try to autocorrect otherwise valid code' do
      source = <<~RUBY
        module MyModule
          requires_ancestor Kernel, Minitest::Assertions,
            SomeOtherModule, Foo::Bar

          def foo(one, two)
            # Method body
          end
        end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          module MyModule
            requires_ancestor Kernel
            requires_ancestor Minitest::Assertions
            requires_ancestor SomeOtherModule
            requires_ancestor Foo::Bar

            def foo(one, two)
              # Method body
            end
          end
        RUBY
    end

    it 'autocorrects abstract classes correctly' do
      source = <<~RUBY
        class MyClass
          extend T::Sig
          extend T::Helpers
          requires_ancestor Kernel, Minitest::Assertions, Foo::Bar

          abstract!

          sig {abstract.void}
          def self.foo; end
        end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          class MyClass
            extend T::Sig
            extend T::Helpers
            requires_ancestor Kernel
            requires_ancestor Minitest::Assertions
            requires_ancestor Foo::Bar

            abstract!

            sig {abstract.void}
            def self.foo; end
          end
        RUBY
    end
  end
end
