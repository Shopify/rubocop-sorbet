# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::AnonymousClassBlock, :config) do
  include RuboCop::RSpec::ExpectOffense

  it "registers an offense when initializing an anonymous class with a block" do
    expect_offense(<<~RUBY)
      Class.new do
      ^^^^^^^^^ Avoid defining anonymous classes with a block.
        def this_is_bad
        end
      end
    RUBY

    expect_offense(<<~RUBY)
      Foo = Class.new { THIS_IS_BAD = true }
            ^^^^^^^^^ Avoid defining anonymous classes with a block.
    RUBY
  end

  it "does not register an offense when using a named class" do
    expect_no_offenses(<<~RUBY)
      class Foo
        def this_is_good
        end
      end
    RUBY
  end

  it "does not register an offense when Class.new is not passed a block" do
    expect_no_offenses(<<~RUBY)
      ThisIsGood = Class.new
      Class.new(ThisIsGood)
    RUBY
  end

  context "with an alternative provided" do
    let(:cop_config) do
      {
        "Enabled" => true,
        "Alternative" => alternative,
      }
    end
    let(:alternative) { "some_alternative_method" }

    it "includes the alternative in the offense message" do
      expect_offense(<<~RUBY)
        Class.new do
        ^^^^^^^^^ Avoid defining anonymous classes with a block. Use `some_alternative_method` instead.
          def this_is_bad
          end
        end
      RUBY
    end
  end
end
