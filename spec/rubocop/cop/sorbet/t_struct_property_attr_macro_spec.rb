# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::TStructPropertyAttrMacro, :config) do
  context("when using `const` property") do
    context("and `attr_reader` is used") do
      context("and the names match") do
        it("registers an offense") do
          expect_offense(<<~RUBY)
            class Foo < T::Struct
              attr_reader :bar
                          ^^^^ Do not override `T::Struct` `:bar` property reader unless customizing it.

              const :bar, String
            end
          RUBY
        end

        context("and the order is reversed") do
          it("registers an offense") do
            expect_offense(<<~RUBY)
              class Foo < T::Struct
                const :bar, String

                attr_reader :bar
                            ^^^^ Do not override `T::Struct` `:bar` property reader unless customizing it.
              end
            RUBY
          end
        end
      end

      context("and the names do not match") do
        it("registers no offenses") do
          expect_no_offenses(<<~RUBY)
            class Foo < T::Struct
              attr_reader :other
              const :bar, String
            end
          RUBY
        end
      end
    end

    context("and a matching custom reader is defined without `attr_reader`") do
      it("does not register an offense") do
        expect_no_offenses(<<~RUBY)
          class Foo < T::Struct
            const :bar, String

            def bar
              # ...
            end
          end
        RUBY
      end
    end

    context("and `attr_writer` is used") do
      context("and the names match") do
        it("registers an offense") do
          expect_offense(<<~RUBY)
            class Foo < T::Struct
              attr_writer :bar
                          ^^^^ Use `T::Struct.prop` instead of `attr_writer` to define `:bar` property as mutable.

              const :bar, String
            end
          RUBY
        end

        context("and the order is reversed") do
          it("registers an offense") do
            expect_offense(<<~RUBY)
              class Foo < T::Struct
                const :bar, String

                attr_writer :bar
                            ^^^^ Use `T::Struct.prop` instead of `attr_writer` to define `:bar` property as mutable.
              end
            RUBY
          end
        end
      end

      context("and the names do not match") do
        it("registers no offenses") do
          expect_no_offenses(<<~RUBY)
            class Foo < T::Struct
              attr_writer :other
              const :bar, String
            end
          RUBY
        end
      end
    end

    context("and a matching custom writer is defined without `attr_writer`") do
      it("does not register an offense") do
        expect_no_offenses(<<~RUBY)
          class Foo < T::Struct
            const :bar, String

            def bar=(value)
              # ...
            end
          end
        RUBY
      end
    end

    context("and `attr_accessor` is used") do
      context("and the names match") do
        it("registers an offense") do
          expect_offense(<<~RUBY)
            class Foo < T::Struct
              attr_accessor :bar
                            ^^^^ Use `T::Struct.prop` instead of `attr_accessor` to define `:bar` property as mutable.

              const :bar, String
            end
          RUBY
        end

        context("and the order is reversed") do
          it("registers an offense") do
            expect_offense(<<~RUBY)
              class Foo < T::Struct
                const :bar, String

                attr_accessor :bar
                              ^^^^ Use `T::Struct.prop` instead of `attr_accessor` to define `:bar` property as mutable.
              end
            RUBY
          end
        end
      end

      context("and the names do not match") do
        it("registers no offenses") do
          expect_no_offenses(<<~RUBY)
            class Foo < T::Struct
              attr_accessor :other
              const :bar, String
            end
          RUBY
        end
      end
    end
  end

  context("when using `prop` property") do
    context("and `attr_reader` is used") do
      context("and the names match") do
        it("registers an offense") do
          expect_offense(<<~RUBY)
            class Foo < T::Struct
              attr_reader :bar
                          ^^^^ Do not override `T::Struct` `:bar` property reader unless customizing it.

              prop :bar, String
            end
          RUBY
        end

        context("and the order is reversed") do
          it("registers an offense") do
            expect_offense(<<~RUBY)
              class Foo < T::Struct
                prop :bar, String

                attr_reader :bar
                            ^^^^ Do not override `T::Struct` `:bar` property reader unless customizing it.
              end
            RUBY
          end
        end
      end

      context("and the names do not match") do
        it("registers no offenses") do
          expect_no_offenses(<<~RUBY)
            class Foo < T::Struct
              attr_reader :other
              prop :bar, String
            end
          RUBY
        end
      end
    end

    context("and a matching custom reader is defined without `attr_reader`") do
      it("does not register an offense") do
        expect_no_offenses(<<~RUBY)
          class Foo < T::Struct
            prop :bar, String

            def bar
              # ...
            end
          end
        RUBY
      end
    end

    context("and `attr_writer` is used") do
      context("and the names match") do
        it("registers an offense") do
          expect_offense(<<~RUBY)
            class Foo < T::Struct
              attr_writer :bar
                          ^^^^ Do not override `T::Struct` `:bar` property writer unless customizing it.

              prop :bar, String
            end
          RUBY
        end

        context("and the order is reversed") do
          it("registers an offense") do
            expect_offense(<<~RUBY)
              class Foo < T::Struct
                prop :bar, String

                attr_writer :bar
                            ^^^^ Do not override `T::Struct` `:bar` property writer unless customizing it.
              end
            RUBY
          end
        end
      end

      context("and the names do not match") do
        it("registers no offenses") do
          expect_no_offenses(<<~RUBY)
            class Foo < T::Struct
              attr_writer :other

              prop :bar, String
            end
          RUBY
        end
      end
    end

    context("and a matching custom writer is defined without `attr_writer`") do
      it("does not register an offense") do
        expect_no_offenses(<<~RUBY)
          class Foo < T::Struct
            prop :bar, String

            def bar=(value)
              # ...
            end
          end
        RUBY
      end
    end

    context("and `attr_accessor` is used") do
      context("and the names match") do
        it("registers an offense") do
          expect_offense(<<~RUBY)
            class Foo < T::Struct
              attr_accessor :bar
                            ^^^^ Do not override `T::Struct` `:bar` property accessor unless customizing it.

              prop :bar, String
            end
          RUBY
        end

        context("and the order is reversed") do
          it("registers an offense") do
            expect_offense(<<~RUBY)
              class Foo < T::Struct
                prop :bar, String

                attr_accessor :bar
                              ^^^^ Do not override `T::Struct` `:bar` property accessor unless customizing it.
              end
            RUBY
          end
        end
      end

      context("and the names do not match") do
        it("registers no offenses") do
          expect_no_offenses(<<~RUBY)
            class Foo < T::Struct
              attr_accessor :other
              prop :bar, String
            end
          RUBY
        end
      end
    end
  end

  it "does not error when inspecting an empty class" do
    expect_no_offenses(<<~RUBY)
      class Foo < T::Struct
      end
    RUBY
  end

  it "does not error when inspecting a class with a single macro" do
    expect_no_offenses(<<~RUBY)
      class Foo < T::Struct
        const :bar, String
      end
    RUBY
  end

  it "handles variadic attr_* macros" do
    expect_offense(<<~RUBY)
      class Foo < T::Struct
        attr_reader :foo, :bar, :biz, :baz
                          ^^^^ Do not override `T::Struct` `:bar` property reader unless customizing it.
        const :bar, String
      end
    RUBY
  end

  it "ignores unrelated macros" do
    expect_offense(<<~RUBY)
      class Foo < T::Struct
        attr_reader :foo, :bar
                          ^^^^ Do not override `T::Struct` `:bar` property reader unless customizing it.
        other :foo
        const :bar, String
      end
    RUBY
  end

  it "also detects usage in T::ImmutableStruct" do
    expect_offense(<<~RUBY)
      class Foo < T::ImmutableStruct
        attr_reader :bar
                    ^^^^ Do not override `T::Struct` `:bar` property reader unless customizing it.
        const :bar, String
      end
    RUBY
  end
end
