# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/sorbet/binding_constants_without_type_alias'

RSpec.describe(RuboCop::Cop::Sorbet::BindingConstantWithoutTypeAlias, :config) do
  subject(:cop) { described_class.new(config) }

  def message
    "It looks like you're trying to bind a type to a constant. " \
    'To do this, you must alias the type using `T.type_alias`.'
  end

  def deprecation
    "It looks like you're using the old `T.type_alias` syntax. " \
    '`T.type_alias` now expects a block.' \
    'Run Sorbet with the options "--autocorrect --error-white-list=5043" ' \
    'to automatically upgrade to the new syntax.'
  end

  describe('offenses') do
    it('disallows binding the return value of T.any, T.all, and others, without using T.type_alias') do
      expect_offense(<<~RUBY)
        A = T.any(String, Integer)
            ^^^^^^^^^^^^^^^^^^^^^^ #{message}
        B = T.all(String, Integer)
            ^^^^^^^^^^^^^^^^^^^^^^ #{message}
        C = T.noreturn
            ^^^^^^^^^^ #{message}
        D = T.class_of(String)
            ^^^^^^^^^^^^^^^^^^ #{message}
        E = T.proc.void
            ^^^^^^^^^^^ #{message}
        F = T.untyped
            ^^^^^^^^^ #{message}
        G = T.nilable(String)
            ^^^^^^^^^^^^^^^^^ #{message}
        H = T.self_type
            ^^^^^^^^^^^ #{message}
      RUBY
    end

    it('allows binding the return of T.any, T.all, etc when using T.type_alias') do
      expect_no_offenses(<<~RUBY)
        A = T.type_alias { T.any(String, Integer) }
        B = T.type_alias { T.all(String, Integer) }
        C = T.type_alias { T.noreturn }
        D = T.type_alias { T.class_of(String) }
        E = T.type_alias { T.proc.void }
        F = T.type_alias { T.untyped }
        G = T.type_alias { T.nilable(String) }
        H = T.type_alias { T.self_type }
      RUBY
    end

    it('allows assigning T.let to a constant') do
      expect_no_offenses(<<~RUBY)
        A = T.let(None.new, Optional[T.untyped])
        B = T.let(C, T.proc.void)
      RUBY
    end

    it('allows using the return value of T.any, T.all, etc in a signature definition') do
      expect_no_offenses(<<~RUBY)
        sig { params(foo: T.any(String, Integer)).void }
        def a(foo); end

        sig { params(foo: T.all(String, Integer)).void }
        def b(foo); end

        sig { returns(T.noreturn) }
        def c; end

        sig { params(foo: T.class_of(String)).void }
        def d(foo); end

        sig { params(foo: T.proc.void).void }
        def e(foo); end

        sig { params(foo: T.untyped).void }
        def f(foo); end

        sig { params(foo: T.nilable(String)).void }
        def g(foo); end

        sig { params(foo: T.self_type).void }
        def h(foo); end
      RUBY
    end

    it('autocorrects to T.type_alias') do
      expect(autocorrect_source('Foo = T.any(String, Integer)'))
        .to(eq('Foo = T.type_alias { T.any(String, Integer) }'))
    end

    it("doesn't crash when assigning constants by destructuring") do
      expect_no_offenses(<<~RUBY)
        A, B = [1, 2]
      RUBY
    end

    it('disallows usage of the old T.type_alias() syntax') do
      expect_offense(<<~RUBY)
        A = T.type_alias(T.any(String, Integer))
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{deprecation}
        B = T.type_alias(T.all(String, Integer))
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{deprecation}
        C = T.type_alias(T.noreturn)
            ^^^^^^^^^^^^^^^^^^^^^^^^ #{deprecation}
        D = T.type_alias(T.class_of(String))
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{deprecation}
        E = T.type_alias(T.proc.void)
            ^^^^^^^^^^^^^^^^^^^^^^^^^ #{deprecation}
        F = T.type_alias(T.untyped)
            ^^^^^^^^^^^^^^^^^^^^^^^ #{deprecation}
        G = T.type_alias(T.nilable(String))
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{deprecation}
        H = T.type_alias(T.self_type)
            ^^^^^^^^^^^^^^^^^^^^^^^^^ #{deprecation}
      RUBY
    end
  end
end
