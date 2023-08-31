# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::BuggyObsoleteStrictMemoization, :config) do
  let(:specs_without_sorbet) do
    [
      Gem::Specification.new("foo", "0.0.1"),
      Gem::Specification.new("bar", "0.0.2"),
    ]
  end

  before(:each) do
    allow(Bundler).to(receive(:locked_gems)).and_return(
      Struct.new(:specs).new([
        *specs_without_sorbet,
        Gem::Specification.new("sorbet-static", "0.5.10210"),
      ]),
    )
    allow(cop).to(receive(:configured_indentation_width).and_return(2))
  end

  describe "non-offending cases" do
    it "the new memoization pattern doesn't register any offense" do
      expect_no_offenses(<<~RUBY)
        def foo
          @foo ||= T.let(Foo.new, T.nilable(Foo))
        end
      RUBY
    end

    describe "the correct obsolete memoization pattern" do
      it " doesn't register any offense" do
        expect_no_offenses(<<~RUBY)
          def foo
            @foo = T.let(@foo, T.nilable(Foo))
            @foo ||= Foo.new
          end
        RUBY
      end

      describe "with fully qualified ::T" do
        it " doesn't register any offense" do
          expect_no_offenses(<<~RUBY)
            def foo
              @foo = ::T.let(@foo, ::T.nilable(Foo))
              @foo ||= Foo.new
            end
          RUBY
        end
      end

      describe "with a complex type" do
        it "doesn't register any offense" do
          expect_no_offenses(<<~RUBY)
            def client_info_hash
              @client_info_hash = T.let(@client_info_hash, T.nilable(T::Hash[Symbol, T.untyped]))
              @client_info_hash ||= client_info.to_hash
            end
          RUBY
        end
      end

      describe "with multiline initialization expression" do
        it "doesn't register any offense" do
          expect_no_offenses(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
              @foo ||= multiline_method_call(
                foo,
                bar,
                baz,
              )
            end
          RUBY
        end

        describe "with a gap between the two lines" do
          it "doesn't register any offense" do
            expect_no_offenses(<<~RUBY)
              def foo
                @foo = T.let(@foo, T.nilable(Foo))

                @foo ||= multiline_method_call(
                  foo,
                  bar,
                  baz,
                )
              end
            RUBY
          end
        end
      end

      describe "with non-empty lines between the two lines" do
        it "doesn't register any offense" do
          expect_no_offenses(<<~RUBY)
            def foo
              @foo = T.let(@foo, T.nilable(Foo))
             some_other_computation
              @foo ||= multiline_method_call(
                foo,
                bar,
                baz,
              )
            end
          RUBY
        end
      end

      context "when its not the first line in a method" do
        it "doesn't register any offense" do
          expect_no_offenses(<<~RUBY)
            def foo
              some
              other
              code
              @foo = T.let(@foo, T.nilable(Foo))
              @foo ||= Foo.new
            end
          RUBY
        end
      end
    end
  end

  describe "a mistaken variant of the obsolete memoization pattern" do
    context "not using Sorbet" do
      # If the project is not using Sorbet, the obsolete memoization pattern might be intentional.
      it "does not register an offence" do
        allow(Bundler).to(receive(:locked_gems)).and_return(
          Struct.new(:specs).new(specs_without_sorbet),
        )

        expect_no_offenses(<<~RUBY)
          sig { returns(Foo) }
          def foo
            @foo = T.let(@foo, T.nilable(Foo))
            @foo ||= Foo.new
          end
        RUBY
      end
    end

    it "registers an offence and autocorrects" do
      # This variant would have been a mistake, which would have caused the memoized value to be discarded
      # and recomputed on every call. We can fix it up into the working version.

      expect_offense(<<~RUBY)
        def foo
          @foo = T.let(nil, T.nilable(Foo))
                       ^^^ This might be a mistaken variant of the two-stage workaround that used to be needed for memoization in `#typed: strict` files. See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization.
          @foo ||= Foo.new
        end
      RUBY

      expect_correction(<<~RUBY)
        def foo
          @foo = T.let(@foo, T.nilable(Foo))
          @foo ||= Foo.new
        end
      RUBY
    end
  end
end
