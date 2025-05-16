# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::BlockMethodDefinition, :config) do
  it "registers an offense when defining a method in a block" do
    expect_offense(<<~RUBY)
      yielding_method do
        def bad_method(arg0, arg1 = 1, *args, foo:, bar: nil, **kwargs, &block)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not define methods in blocks (use `define_method` as a workaround).
          if arg0
            arg0 + arg1
          end
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      yielding_method do
        define_method(:bad_method) do |arg0, arg1 = 1, *args, foo:, bar: nil, **kwargs, &block|
          if arg0
            arg0 + arg1
          end
        end
      end
    RUBY
  end

  it "registers an offense when defining a method in a block with numbered arguments" do
    expect_offense(<<~RUBY)
      yielding_method do
        puts _1

        def bad_method(args)
        ^^^^^^^^^^^^^^^^^^^^ Do not define methods in blocks (use `define_method` as a workaround).
        end
      end
    RUBY
  end

  it "registers an offense when defining a class method in a block" do
    expect_offense(<<~RUBY)
      yielding_method do
        def self.bad_method(args)
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not define methods in blocks (use `define_method` as a workaround).
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      yielding_method do
        self.define_singleton_method(:bad_method) do |args|
        end
      end
    RUBY
  end

  it "does not register an offense when using define_method as a workaround" do
    expect_no_offenses(<<~RUBY)
      yielding_method do
        define_method(:good_method) do |args|
        end
      end
    RUBY
  end

  it "does not register an offense when defining a top-level method" do
    expect_no_offenses(<<~RUBY)
      def good_method
      end
    RUBY
  end

  it "does not register an offense when defining a method in a class" do
    expect_no_offenses(<<~RUBY)
      class MyClass
        def good_method
        end
      end
    RUBY
  end

  it "does not register an offense when defining a method in a named class defined Class.new" do
    expect_no_offenses(<<~RUBY)
      MyClass = Class.new do
        def good_method
        end
      end
    RUBY
  end

  it "registers an offense when defining a method in an anonymous class" do
    expect_offense(<<~RUBY)
      Class.new do
        def bad_method(args)
        ^^^^^^^^^^^^^^^^^^^^ Do not define methods in blocks (use `define_method` as a workaround).
        end
      end
    RUBY
  end
end
