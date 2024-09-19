# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::Refinement, :config) do
  it "reports an offense for use of using" do
    expect_offense(<<~RUBY, "my_class.rb")
      using MyRefinement
      ^^^^^^^^^^^^^^^^^^ Do not use Ruby Refinements library as it is not supported by Sorbet.
    RUBY
  end

  it "reports an offense for use of refine" do
    expect_offense(<<~RUBY, "my_refinement.rb")
      module MyRefinement
        refine(String) do
        ^^^^^^^^^^^^^^ Do not use Ruby Refinements library as it is not supported by Sorbet.
          def to_s
            "foo"
          end
        end
      end
    RUBY
  end

  it "reports no offense for use of using with non-const argument" do
    expect_no_offenses(<<~RUBY, "my_class.rb")
      using "foo"
    RUBY
  end

  it "reports no offense for use of refine with non-const argument" do
    expect_no_offenses(<<~RUBY, "my_refinement.rb")
      module MyRefinement
        refine "foo" do
          def to_s
            "foo"
          end
        end
      end
    RUBY
  end

  it "reports no offense for use of refine with no block argument" do
    expect_no_offenses(<<~RUBY, "my_refinement.rb")
      module MyRefinement
        refine(String)
      end
    RUBY
  end

  it "reports no offense for use of refine outside of module" do
    expect_no_offenses(<<~RUBY, "my_refinement.rb")
      module MyNamespace
        class MyClass
          refine(String) do
            def to_s
              "foo"
            end
          end
        end
      end
    RUBY
  end
end
