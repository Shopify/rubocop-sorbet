# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(RuboCop::Cop::Sorbet::MutableTLetConstant, :config) do
  # subject(:cop) { described_class.new(config) }
  let(:prefix) { nil }

  shared_examples 'mutable objects' do |o|
    context 'when assigning with =' do
      it "registers an offense for #{o} assigned to a constant" do
        source = [prefix, "CONST = T.let(#{o}, Object)"].compact.join("\n")
        inspect_source(source)
        expect(cop.offenses.size).to(eq(1))
      end

      it 'auto-corrects by adding .freeze' do
        source = [prefix, "CONST = T.let(#{o}, Object)"].compact.join("\n")
        new_source = autocorrect_source(source)
        expect(new_source).to(eq([prefix, "CONST = T.let(#{o}.freeze, Object)"].compact.join("\n")))
      end
    end

    context 'when assigning with ||=' do
      it "registers an offense for #{o} assigned to a constant" do
        source = [prefix, "CONST ||= T.let(#{o}, Object)"].compact.join("\n")
        inspect_source(source)
        expect(cop.offenses.size).to(eq(1))
      end

      it 'auto-corrects by adding .freeze' do
        source = [prefix, "CONST ||= T.let(#{o}, Object)"].compact.join("\n")
        new_source = autocorrect_source(source)
        expect(new_source).to(eq([prefix, "CONST ||= T.let(#{o}.freeze, Object)"].compact.join("\n")))
      end
    end
  end

  shared_examples 'immutable objects' do |o|
    it "allows #{o} to be assigned to a constant" do
      source = [prefix, "CONST = T.let(#{o}, Object)"].compact.join("\n")
      expect_no_offenses(source)
    end

    it "allows #{o} to be ||= to a constant" do
      source = [prefix, "CONST ||= T.let(#{o}, Object)"].compact.join("\n")
      expect_no_offenses(source)
    end
  end

  context 'Strict: false' do
    let(:cop_config) { { 'EnforcedStyle' => 'literals' } }

    it_behaves_like 'mutable objects', '[1, 2, 3]'
    it_behaves_like 'mutable objects', '%w(a b c)'
    it_behaves_like 'mutable objects', '{ a: 1, b: 2 }'
    it_behaves_like 'mutable objects', "'str'"
    it_behaves_like 'mutable objects', '"top#{1 + 2}"'

    it_behaves_like 'immutable objects', '1'
    it_behaves_like 'immutable objects', '1.5'
    it_behaves_like 'immutable objects', ':sym'
    it_behaves_like 'immutable objects', 'FOO + BAR'
    it_behaves_like 'immutable objects', 'FOO - BAR'
    it_behaves_like 'immutable objects', "'foo' + 'bar'"
    it_behaves_like 'immutable objects', "ENV['foo']"

    it 'allows method call assignments' do
      expect_no_offenses('TOP_TEST = T.let(Something.new, Something)')
    end

    context 'when assigning a word array' do
      it 'auto-corrects by adding .freeze' do
        new_source = autocorrect_source('XXX = T.let(%w(YYY ZZZ), T::Array[String])')
        expect(new_source).to(eq('XXX = T.let(%w(YYY ZZZ).freeze, T::Array[String])'))
      end
    end

    context 'when assigning a range (irange) without parenthesis' do
      it 'adds parenthesis when auto-correcting' do
        new_source = autocorrect_source('XXX = T.let(1..99, T::Range[Integer])')
        expect(new_source).to(eq('XXX = T.let((1..99).freeze, T::Range[Integer])'))
      end

      it 'does not add parenthesis to range enclosed in parentheses' do
        new_source = autocorrect_source('XXX = T.let((1..99), T::Range[Integer])')
        expect(new_source).to(eq('XXX = T.let((1..99).freeze, T::Range[Integer])'))
      end
    end

    context 'when assigning a range (erange) without parenthesis' do
      it 'adds parenthesis when auto-correcting' do
        new_source = autocorrect_source('XXX = T.let(1...99, T::Range[Integer])')
        expect(new_source).to(eq('XXX = T.let((1...99).freeze, T::Range[Integer])'))
      end

      it 'does not add parenthesis to range enclosed in parentheses' do
        new_source = autocorrect_source('XXX = T.let((1...99), T::Range[Integer])')
        expect(new_source).to(eq('XXX = T.let((1...99).freeze, T::Range[Integer])'))
      end
    end

    context 'when the constant is a frozen string literal' do
      # TODO : It is not yet decided when frozen string will be the default.
      # It has been abandoned in the Ruby 3.0 period, but may default in
      # the long run. So these tests are left with a provisional value of 4.0.
      if RuboCop::TargetRuby.supported_versions.include?(4.0)
        context 'when the target ruby version >= 4.0' do
          let(:ruby_version) { 4.0 }

          context 'when the frozen string literal comment is missing' do
            it_behaves_like 'immutable objects', '"#{a}"'
          end

          context 'when the frozen string literal comment is true' do
            let(:prefix) { '# frozen_string_literal: true' }

            it_behaves_like 'immutable objects', '"#{a}"'
          end

          context 'when the frozen string literal comment is false' do
            let(:prefix) { '# frozen_string_literal: false' }

            it_behaves_like 'immutable objects', '"#{a}"'
          end
        end
      end

      context 'when the frozen string literal comment is missing' do
        it_behaves_like 'mutable objects', '"#{a}"'
      end

      context 'when the frozen string literal comment is true' do
        let(:prefix) { '# frozen_string_literal: true' }

        it_behaves_like 'immutable objects', '"#{a}"'
      end

      context 'when the frozen string literal comment is false' do
        let(:prefix) { '# frozen_string_literal: false' }

        it_behaves_like 'mutable objects', '"#{a}"'
      end
    end
  end

  context 'Strict: true' do
    let(:cop_config) { { 'EnforcedStyle' => 'strict' } }

    it_behaves_like 'mutable objects', '[1, 2, 3]'
    it_behaves_like 'mutable objects', '%w(a b c)'
    it_behaves_like 'mutable objects', '{ a: 1, b: 2 }'
    it_behaves_like 'mutable objects', "'str'"
    it_behaves_like 'mutable objects', '"top#{1 + 2}"'
    it_behaves_like 'mutable objects', 'Something.new'

    it_behaves_like 'immutable objects', '1'
    it_behaves_like 'immutable objects', '1.5'
    it_behaves_like 'immutable objects', ':sym'
    it_behaves_like 'immutable objects', "ENV['foo']"
    it_behaves_like 'immutable objects', 'OTHER_CONST'
    it_behaves_like 'immutable objects', 'Namespace::OTHER_CONST'
    it_behaves_like 'immutable objects', 'Struct.new'
    it_behaves_like 'immutable objects', 'Struct.new(:a, :b)'

    it 'allows calls to freeze' do
      expect_no_offenses(<<~RUBY)
        CONST = T.let([1].freeze, T::Array[Integer])
      RUBY
    end

    context 'when assigning with an operator' do
      shared_examples 'operator methods' do |o|
        it 'registers an offense' do
          inspect_source("CONST = T.let(FOO #{o} BAR, Numeric)")

          expect(cop.offenses.size).to(eq(1))
          expect(cop.highlights).to(eq(["FOO #{o} BAR"]))
        end

        it 'corrects by wrapping in parentheses and calling freeze' do
          new_source = autocorrect_source(<<~RUBY)
            CONST = T.let(FOO #{o} BAR, Numeric)
          RUBY

          expect(new_source).to(eq(<<~RUBY))
            CONST = T.let((FOO #{o} BAR).freeze, Numeric)
          RUBY
        end
      end

      it_behaves_like 'operator methods', '+'
      it_behaves_like 'operator methods', '-'
      it_behaves_like 'operator methods', '*'
      it_behaves_like 'operator methods', '/'
      it_behaves_like 'operator methods', '%'
      it_behaves_like 'operator methods', '**'
    end

    context 'when assigning with multiple operator calls' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          FOO = T.let([1].freeze, T::Array[Integer])
          BAR = T.let([2].freeze, T::Array[Integer])
          BAZ = T.let([3].freeze, T::Array[Integer])
          CONST = T.let(FOO + BAR + BAZ, Object)
                        ^^^^^^^^^^^^^^^ Freeze mutable objects in T.let expressions assigned to constants.
        RUBY
      end

      it 'corrects by wrapping in parens and calling freeze' do
        new_source = autocorrect_source(<<~RUBY)
          FOO = T.let([1].freeze, T::Array[Integer])
          BAR = T.let([2].freeze, T::Array[Integer])
          BAZ = T.let([3].freeze, T::Array[Integer])
          CONST = T.let(FOO + BAR + BAZ, Object)
        RUBY

        expect(new_source).to(eq(<<~RUBY))
          FOO = T.let([1].freeze, T::Array[Integer])
          BAR = T.let([2].freeze, T::Array[Integer])
          BAZ = T.let([3].freeze, T::Array[Integer])
          CONST = T.let((FOO + BAR + BAZ).freeze, Object)
        RUBY
      end
    end

    context 'methods and operators that produce frozen objects' do
      it 'accepts assigning to an environment variable with a fallback' do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(ENV['foo'] || 'foo', String)
        RUBY
      end

      it 'accepts operating on a constant and an interger' do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(FOO + 2, Integer)
        RUBY
      end

      it 'accepts operating on multiple integers' do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(1 + 2, Integer)
        RUBY
      end

      it 'accepts operating on a constant and a float' do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(FOO + 2.1, Float)
        RUBY
      end

      it 'accepts operating on multiple floats' do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(1.2 + 2.1, Float)
        RUBY
      end

      it 'accepts comparison operators' do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(FOO == BAR, T::Boolean)
        RUBY
      end

      it 'accepts checking fixed size' do
        expect_no_offenses(<<~RUBY)
          CONST = T.let([1, 2, 3].count, Integer)
          CONST = T.let('foo'.count('f'), Integer)
          CONST = T.let([1, 2, 3].count { |n| n > 2 }, Integer)
          CONST = T.let([1, 2, 3].count(2) { |n| n > 2 }, Integer)
          CONST = T.let('foo'.length, Integer)
          CONST = T.let('foo'.size, Integger)
        RUBY
      end
    end

    context 'operators that produce unfrozen objects' do
      it 'registers an offense when operating on a constant and a string' do
        expect_offense(<<~RUBY)
          CONST = T.let(FOO + 'bar', String)
                        ^^^^^^^^^^^ Freeze mutable objects in T.let expressions assigned to constants.
        RUBY
      end

      it 'registers an offense when operating on multiple strings' do
        expect_offense(<<~RUBY)
          CONST = T.let('foo' + 'bar' + 'baz', String)
                        ^^^^^^^^^^^^^^^^^^^^^ Freeze mutable objects in T.let expressions assigned to constants.
        RUBY
      end
    end

    context 'when assigning a word array' do
      it 'auto-corrects by adding .freeze' do
        new_source = autocorrect_source('XXX = T.let(%w(YYY ZZZ), T::Array[String])')
        expect(new_source).to(eq('XXX = T.let(%w(YYY ZZZ).freeze, T::Array[String])'))
      end
    end

    context 'when the frozen string literal comment is missing' do
      it_behaves_like 'mutable objects', '"#{a}"'
    end

    context 'when the frozen string literal comment is true' do
      let(:prefix) { '# frozen_string_literal: true' }

      it_behaves_like 'immutable objects', '"#{a}"'
    end

    context 'when the frozen string literal comment is false' do
      let(:prefix) { '# frozen_string_literal: false' }

      it_behaves_like 'mutable objects', '"#{a}"'
    end
  end
end
