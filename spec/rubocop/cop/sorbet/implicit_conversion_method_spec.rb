# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ImplicitConversionMethod, :config) do
  def message
    "Avoid implicit conversion methods, as Sorbet does not support them. " \
    "Explicity convert to the desired type instead."
  end

  it "adds offense when defining implicit conversion instance method" do
    expect_offense(<<~RUBY)
      def to_ary
      ^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it "adds offense when defining implicit conversion class method" do
    expect_offense(<<~RUBY)
      def self.to_int
      ^^^^^^^^^^^^^^^ #{message}
      end
    RUBY
  end

  it "does not add offense when method arguments exist" do
    expect_no_offenses(<<~RUBY)
      def to_int(foo)
      end
    RUBY
  end

  it "adds offense when declaring an implicit conversion method via alias" do
    expect_offense(<<~RUBY)
      alias to_str to_s
            ^^^^^^ #{message}
    RUBY
  end

  it "adds offense when declaring an implicit conversion method via alias_method" do
    expect_offense(<<~RUBY)
      alias_method :to_hash, :to_h
                   ^^^^^^^^ #{message}
    RUBY
  end
end
