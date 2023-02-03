# frozen_string_literal: true

RSpec.describe(RuboCop::Cop::Sorbet::RedundantExtendTSig, :config) do
  let(:config) { RuboCop::Config.new }
  let(:message) { "Do not redundantly `extend T::Sig` when it is already included in all modules." }

  shared_examples "block form" do |label, header|
    it "registers an offense when using `extend T::Sig` #{label}" do
      expect_offense(<<~RUBY)
        #{header}
          extend T::Sig
          ^^^^^^^^^^^^^ #{message}
        end
      RUBY

      expect_correction(<<~RUBY)
        #{header}
          #{trailing_whitespace}
        end
      RUBY
    end

    private

    def trailing_whitespace
      ""
    end
  end

  include_examples "block form", "in a module", "module M"
  include_examples "block form", "in a class", "class C"
  include_examples "block form", "in an anonymous module", "Module.new do"
  include_examples "block form", "in an anonymous class", "Class.new do"
  include_examples "block form", "in `self`'s singleton class", "class << self"
  include_examples "block form", "in an arbitrary singleton class", "class << object"
  include_examples "block form", "in a module with other contents", <<~RUBY.chomp
    module M
      extend SomethingElse
  RUBY

  it "registers an offense when using `extend T::Sig` on its own" do
    expect_offense(<<~RUBY)
      extend T::Sig
      ^^^^^^^^^^^^^ #{message}
    RUBY

    expect_correction(a_blank_line)
  end

  it "registers an offense when using `extend ::T::Sig` (fully qualified)" do
    expect_offense(<<~RUBY)
      extend ::T::Sig
      ^^^^^^^^^^^^^^^ #{message}
    RUBY

    expect_correction(a_blank_line)
  end

  it "registers an offense when using `extend T::Sig` with an explicit receiver" do
    expect_offense(<<~RUBY)
      some_module.extend T::Sig
      ^^^^^^^^^^^^^^^^^^^^^^^^^ #{message}
    RUBY

    expect_correction(a_blank_line)
  end

  it "does not register an offense when extending other modules in the T namespace" do
    expect_no_offenses(<<~RUBY)
      module M
        extend T::Helpers
      end
    RUBY
  end

  private

  def a_blank_line
    "\n"
  end
end
