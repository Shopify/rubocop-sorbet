# frozen_string_literal: true

require "spec_helper"

require "rubocop/cop/style/mutable_constant"

RSpec.describe(RuboCop::Cop::Style::MutableConstant, :config) do
  let(:prefix) { nil }

  shared_examples "mutable objects" do |o|
    context "using T.let" do
      context "when assigning with =" do
        it "registers an offense for #{o} assigned to a constant " \
          "and corrects by adding .freeze" do
          expect_offense([prefix, <<~RUBY].compact.join("\n"), o: o)
            CONST = T.let(%{o}, Object)
                          ^{o} Freeze mutable objects assigned to constants.
          RUBY
          expect_correction([prefix, <<~RUBY].compact.join("\n"))
            CONST = T.let(#{o}.freeze, Object)
          RUBY
        end
      end

      context "when assigning with ||=" do
        it "registers an offense for #{o} assigned to a constant " \
          "and corrects by adding .freeze" do
          expect_offense([prefix, <<~RUBY].compact.join("\n"), o: o)
            CONST ||= T.let(%{o}, Object)
                            ^{o} Freeze mutable objects assigned to constants.
          RUBY
          expect_correction([prefix, <<~RUBY].compact.join("\n"))
            CONST ||= T.let(#{o}.freeze, Object)
          RUBY
        end
      end
    end

    context "not using T.let" do
      context "when assigning with =" do
        it "registers an offense for #{o} assigned to a constant " \
          "and corrects by adding .freeze" do
          expect_offense([prefix, <<~RUBY].compact.join("\n"), o: o)
            CONST = %{o}
                    ^{o} Freeze mutable objects assigned to constants.
          RUBY
          expect_correction([prefix, <<~RUBY].compact.join("\n"))
            CONST = #{o}.freeze
          RUBY
        end
      end

      context "when assigning with ||=" do
        it "registers an offense for #{o} assigned to a constant " \
          "and corrects by adding .freeze" do
          expect_offense([prefix, <<~RUBY].compact.join("\n"), o: o)
            CONST ||= %{o}
                      ^{o} Freeze mutable objects assigned to constants.
          RUBY
          expect_correction([prefix, <<~RUBY].compact.join("\n"))
            CONST ||= #{o}.freeze
          RUBY
        end
      end
    end
  end

  shared_examples "immutable objects" do |o|
    context "using T.let" do
      it "allows #{o} to be assigned to a constant" do
        const = if o.start_with?("<<~HERE")
          heredoc = o.delete_prefix("<<~HERE")
          "CONST = T.let(<<~HERE, Object)#{heredoc}"
        else
          "CONST = T.let(#{o.chomp}, Object)"
        end
        source = [prefix, const].compact.join("\n")
        expect_no_offenses(source)
      end

      it "allows #{o} to be ||= to a constant" do
        const = if o.start_with?("<<~HERE")
          heredoc = o.delete_prefix("<<~HERE")
          "CONST ||= T.let(<<~HERE, Object)#{heredoc}"
        else
          "CONST ||= T.let(#{o.chomp}, Object)"
        end
        source = [prefix, const].compact.join("\n")
        expect_no_offenses(source)
      end
    end

    context "not using T.let" do
      it "allows #{o} to be assigned to a constant" do
        source = [prefix, "CONST = #{o}"].compact.join("\n")
        expect_no_offenses(source)
      end

      it "allows #{o} to be ||= to a constant" do
        source = [prefix, "CONST ||= #{o}"].compact.join("\n")
        expect_no_offenses(source)
      end
    end
  end

  shared_examples "literals that are frozen" do |o|
    let(:prefix) { o }

    it_behaves_like "immutable objects", "[1, 2, 3]"
    it_behaves_like "immutable objects", "%w(a b c)"
    it_behaves_like "immutable objects", "{ a: 1, b: 2 }"
    it_behaves_like "immutable objects", "'str'"
    it_behaves_like "immutable objects", '"top#{1 + 2}"'
    it_behaves_like "immutable objects", "1"
    it_behaves_like "immutable objects", "1.5"
    it_behaves_like "immutable objects", ":sym"
    it_behaves_like "immutable objects", "FOO + BAR"
    it_behaves_like "immutable objects", "FOO - BAR"
    it_behaves_like "immutable objects", "'foo' + 'bar'"
    it_behaves_like "immutable objects", "ENV['foo']"
    it_behaves_like "immutable objects", "::ENV['foo']"
  end

  shared_examples "literals that are not frozen" do |o|
    let(:prefix) { o }

    it_behaves_like "mutable objects", "[1, 2, 3]"
    it_behaves_like "mutable objects", "%w(a b c)"
    it_behaves_like "mutable objects", "{ a: 1, b: 2 }"
    it_behaves_like "mutable objects", "'str'"
    it_behaves_like "mutable objects", '"top#{1 + 2}"'

    it_behaves_like "immutable objects", "1"
    it_behaves_like "immutable objects", "1.5"
    it_behaves_like "immutable objects", ":sym"
    it_behaves_like "immutable objects", "FOO + BAR"
    it_behaves_like "immutable objects", "FOO - BAR"
    it_behaves_like "immutable objects", "'foo' + 'bar'"
    it_behaves_like "immutable objects", "ENV['foo']"
    it_behaves_like "immutable objects", "::ENV['foo']"
  end

  shared_examples "string literal" do
    # TODO : It is not yet decided when frozen string will be the default.
    # It has been abandoned in the Ruby 3.0 period, but may default in
    # the long run. So these tests are left with a provisional value of 4.0.
    if RuboCop::TargetRuby.supported_versions.include?(4.0)
      context "when the target ruby version >= 4.0" do
        let(:ruby_version) { 4.0 }

        context "when the frozen string literal comment is missing" do
          it_behaves_like "immutable objects", '"#{a}"'
        end

        context "when the frozen string literal comment is true" do
          let(:prefix) { "# frozen_string_literal: true" }

          it_behaves_like "immutable objects", '"#{a}"'
        end

        context "when the frozen string literal comment is false" do
          let(:prefix) { "# frozen_string_literal: false" }

          it_behaves_like "immutable objects", '"#{a}"'
        end
      end
    end

    context "Ruby 3.0 or higher", :ruby30 do
      context "when the frozen string literal comment is missing" do
        it_behaves_like "mutable objects", '"#{a}"'
      end

      context "when the frozen string literal comment is true" do
        let(:prefix) { "# frozen_string_literal: true" }

        it_behaves_like "mutable objects", '"#{a}"'
        it_behaves_like "immutable objects", <<~'RUBY'
          <<~HERE
            foo
            bar
          HERE
        RUBY
        it "registers an offense when using interpolated heredoc constant" do
          expect_offense(<<~'RUBY')
            # frozen_string_literal: true

            CONST = T.let(<<~HERE, Object)
                          ^^^^^^^ Freeze mutable objects assigned to constants.
              foo #{use_interpolation}
              bar
            HERE
          RUBY
        end

        it "does not register an offense when using a multiline string" do
          expect_no_offenses(<<~RUBY)
            # frozen_string_literal: true

            CONST = T.let('foo' \
                    'bar', Object)
          RUBY
        end

        it "registers an offense when using a multiline string with interpolation" do
          expect_offense(<<~'RUBY')
            # frozen_string_literal: true

            CONST = T.let("#{foo}" \
                          ^^^^^^^^^^ Freeze mutable objects assigned to constants.
                    'bar', Object)
          RUBY
        end
      end

      context "when the frozen string literal comment is false" do
        let(:prefix) { "# frozen_string_literal: false" }

        it_behaves_like "mutable objects", '"#{a}"'
      end
    end

    context "Ruby 2.7 or lower", :ruby27 do
      context "when the frozen string literal comment is missing" do
        it_behaves_like "mutable objects", '"#{a}"'
      end

      context "when the frozen string literal comment is true" do
        let(:prefix) { "# frozen_string_literal: true" }

        it_behaves_like "immutable objects", '"#{a}"'
        it_behaves_like "immutable objects", <<~'RUBY'
          <<~HERE
            foo
            bar
          HERE
        RUBY
        it "does not register an offense when using interpolated heredoc constant" do
          expect_no_offenses(<<~'RUBY')
            # frozen_string_literal: true

            CONST = T.let(<<~HERE, Object)
              foo #{use_interpolation}
              bar
            HERE
          RUBY
        end

        it "does not register an offense when using a multiline string" do
          expect_no_offenses(<<~RUBY)
            # frozen_string_literal: true

            CONST = T.let('foo' \
                    'bar', Object)
          RUBY
        end
      end

      context "when the frozen string literal comment is false" do
        let(:prefix) { "# frozen_string_literal: false" }

        it_behaves_like "mutable objects", '"#{a}"'
      end
    end
  end

  context "Strict: false" do
    let(:cop_config) { { "EnforcedStyle" => "literals" } }

    it_behaves_like "mutable objects", "[1, 2, 3]"
    it_behaves_like "mutable objects", "%w(a b c)"
    it_behaves_like "mutable objects", "{ a: 1, b: 2 }"
    it_behaves_like "mutable objects", "'str'"
    it_behaves_like "mutable objects", '"top#{1 + 2}"'

    it_behaves_like "immutable objects", "1"
    it_behaves_like "immutable objects", "1.5"
    it_behaves_like "immutable objects", ":sym"
    it_behaves_like "immutable objects", "FOO + BAR"
    it_behaves_like "immutable objects", "FOO - BAR"
    it_behaves_like "immutable objects", "'foo' + 'bar'"
    it_behaves_like "immutable objects", "ENV['foo']"
    it_behaves_like "immutable objects", "::ENV['foo']"

    it "allows method call assignments" do
      expect_no_offenses("TOP_TEST = Something.new")
    end

    context "when assigning an array without brackets" do
      it "does not insert brackets for %w() arrays" do
        expect_offense(<<~RUBY)
          XXX = T.let(%w(YYY ZZZ), Object)
                      ^^^^^^^^^^^ Freeze mutable objects assigned to constants.
        RUBY

        expect_correction(<<~RUBY)
          XXX = T.let(%w(YYY ZZZ).freeze, Object)
        RUBY
      end
    end

    # Ruby 3.0's Regexp and Range literals are frozen.
    #
    # https://bugs.ruby-lang.org/issues/15504
    # https://bugs.ruby-lang.org/issues/16377
    context "Ruby 3.0 or higher", :ruby30 do
      context "when assigning a regexp" do
        it "does not register an offense" do
          expect_no_offenses(<<~RUBY)
            XXX = T.let(/regexp/, Object)
          RUBY
        end
      end

      context "when assigning a range (irange)" do
        it "does not register an offense when without parenthesis" do
          expect_no_offenses(<<~RUBY)
            XXX = T.let(1..99, Object)
          RUBY
        end

        it "does not register an offense when with parenthesis" do
          expect_no_offenses(<<~RUBY)
            XXX = T.let((1..99), Object)
          RUBY
        end
      end

      context "when assigning a range (erange)" do
        it "does not register an offense when without parenthesis" do
          expect_no_offenses(<<~RUBY)
            XXX = T.let(1...99, Object)
          RUBY
        end

        it "does not register an offense when with parenthesis" do
          expect_no_offenses(<<~RUBY)
            XXX = T.let((1...99), Object)
          RUBY
        end
      end

      context "when using shareable_constant_value" do
        it_behaves_like "literals that are frozen", "# shareable_constant_value: literal"
        it_behaves_like "literals that are frozen", "# shareable_constant_value: experimental_everything"
        it_behaves_like "literals that are frozen", "# shareable_constant_value: experimental_copy"
        it_behaves_like "literals that are not frozen", "# shareable_constant_value: none"
      end

      it "raises offense when shareable_constant_value is specified as an inline comment" do
        expect_offense(<<~RUBY)
          X = T.let([1, 2, 3], Object) # shareable_constant_value: literal
                    ^^^^^^^^^ Freeze mutable objects assigned to constants.
          Y = T.let([4, 5, 6], Object)
                    ^^^^^^^^^ Freeze mutable objects assigned to constants.
        RUBY
      end

      it "raises offense only for shareable_constant_value as none when set in the order of: " \
        "literal, none and experimental_everything" do
        expect_offense(<<~RUBY)
          # shareable_constant_value: literal
          X = T.let([1, 2, 3], Object)
          # shareable_constant_value: none
          Y = T.let([4, 5, 6], Object)
                    ^^^^^^^^^ Freeze mutable objects assigned to constants.
          # shareable_constant_value: experimental_everything
          Z = T.let([7, 8, 9], Object)
        RUBY
      end
    end

    context "Ruby 2.7 or lower", :ruby27 do
      context "when assigning a regexp" do
        it "registers an offense" do
          expect_offense(<<~RUBY)
            XXX = T.let(/regexp/, Object)
                        ^^^^^^^^ Freeze mutable objects assigned to constants.
          RUBY

          expect_correction(<<~RUBY)
            XXX = T.let(/regexp/.freeze, Object)
          RUBY
        end
      end

      context "when assigning a range (irange) without parenthesis" do
        it "adds parenthesis when auto-correcting" do
          expect_offense(<<~RUBY)
            XXX = T.let(1..99, Object)
                        ^^^^^ Freeze mutable objects assigned to constants.
          RUBY

          expect_correction(<<~RUBY)
            XXX = T.let((1..99).freeze, Object)
          RUBY
        end

        it "does not insert parenthesis to range enclosed in parentheses" do
          expect_offense(<<~RUBY)
            XXX = T.let((1..99), Object)
                        ^^^^^^^ Freeze mutable objects assigned to constants.
          RUBY

          expect_correction(<<~RUBY)
            XXX = T.let((1..99).freeze, Object)
          RUBY
        end
      end

      context "when assigning a range (erange) without parenthesis" do
        it "adds parenthesis when auto-correcting" do
          expect_offense(<<~RUBY)
            XXX = T.let(1...99, Object)
                        ^^^^^^ Freeze mutable objects assigned to constants.
          RUBY

          expect_correction(<<~RUBY)
            XXX = T.let((1...99).freeze, Object)
          RUBY
        end

        it "does not insert parenthesis to range enclosed in parentheses" do
          expect_offense(<<~RUBY)
            XXX = T.let((1...99), Object)
                        ^^^^^^^^ Freeze mutable objects assigned to constants.
          RUBY

          expect_correction(<<~RUBY)
            XXX = T.let((1...99).freeze, Object)
          RUBY
        end
      end

      context "when using shareable_constant_values" do
        it_behaves_like "literals that are not frozen", "# shareable_constant_value: literal"
        it_behaves_like "literals that are not frozen", "# shareable_constant_value: experimental_everything"
        it_behaves_like "literals that are not frozen", "# shareable_constant_value: experimental_copy"
        it_behaves_like "literals that are not frozen", "# shareable_constant_value: none"
      end
    end

    it_behaves_like "string literal"
  end

  context "Strict: true" do
    let(:cop_config) { { "EnforcedStyle" => "strict" } }

    it_behaves_like "mutable objects", "[1, 2, 3]"
    it_behaves_like "mutable objects", "%w(a b c)"
    it_behaves_like "mutable objects", "{ a: 1, b: 2 }"
    it_behaves_like "mutable objects", "'str'"
    it_behaves_like "mutable objects", '"top#{1 + 2}"'
    it_behaves_like "mutable objects", "Something.new"

    it_behaves_like "immutable objects", "1"
    it_behaves_like "immutable objects", "1.5"
    it_behaves_like "immutable objects", ":sym"
    it_behaves_like "immutable objects", "ENV['foo']"
    it_behaves_like "immutable objects", "::ENV['foo']"
    it_behaves_like "immutable objects", "OTHER_CONST"
    it_behaves_like "immutable objects", "::OTHER_CONST"
    it_behaves_like "immutable objects", "Namespace::OTHER_CONST"
    it_behaves_like "immutable objects", "::Namespace::OTHER_CONST"
    it_behaves_like "immutable objects", "Struct.new"
    it_behaves_like "immutable objects", "::Struct.new"
    it_behaves_like "immutable objects", "Struct.new(:a, :b)"
    it_behaves_like "immutable objects", <<~RUBY
      Struct.new(:node) do
        def assignment?
          true
        end
      end
    RUBY

    it "allows calls to freeze" do
      expect_no_offenses(<<~RUBY)
        CONST = T.let([1].freeze, Object)
      RUBY
    end

    context "when assigning with an operator" do
      shared_examples "operator methods" do |o|
        it "registers an offense and corrects with parens and freeze" do
          expect_offense(<<~RUBY, o: o)
            CONST = T.let(FOO %{o} BAR, Object)
                          ^^^^^{o}^^^^ Freeze mutable objects assigned to constants.
          RUBY

          expect_correction(<<~RUBY)
            CONST = T.let((FOO #{o} BAR).freeze, Object)
          RUBY
        end
      end

      it_behaves_like "operator methods", "+"
      it_behaves_like "operator methods", "-"
      it_behaves_like "operator methods", "*"
      it_behaves_like "operator methods", "/"
      it_behaves_like "operator methods", "%"
      it_behaves_like "operator methods", "**"
    end

    context "when assigning with multiple operator calls" do
      it "registers an offense and corrects with parens and freeze" do
        expect_offense(<<~RUBY)
          FOO = [1].freeze
          BAR = [2].freeze
          BAZ = [3].freeze
          CONST = T.let(FOO + BAR + BAZ, Object)
                        ^^^^^^^^^^^^^^^ Freeze mutable objects assigned to constants.
        RUBY

        expect_correction(<<~RUBY)
          FOO = [1].freeze
          BAR = [2].freeze
          BAZ = [3].freeze
          CONST = T.let((FOO + BAR + BAZ).freeze, Object)
        RUBY
      end
    end

    context "methods and operators that produce frozen objects" do
      it "accepts assigning to an environment variable with a fallback" do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(ENV['foo'] || 'foo', Object)
        RUBY
        expect_no_offenses(<<~RUBY)
          CONST = T.let(::ENV['foo'] || 'foo', Object)
        RUBY
      end

      it "accepts operating on a constant and an interger" do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(FOO + 2, Object)
        RUBY
      end

      it "accepts operating on multiple integers" do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(1 + 2, Object)
        RUBY
      end

      it "accepts operating on a constant and a float" do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(FOO + 2.1, Object)
        RUBY
      end

      it "accepts operating on multiple floats" do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(1.2 + 2.1, Object)
        RUBY
      end

      it "accepts comparison operators" do
        expect_no_offenses(<<~RUBY)
          CONST = T.let(FOO == BAR, Object)
        RUBY
      end

      it "accepts checking fixed size" do
        expect_no_offenses(<<~RUBY)
          CONST = T.let('foo'.count, Object)
          CONST = T.let('foo'.count('f'), Object)
          CONST = T.let([1, 2, 3].count { |n| n > 2 }, Object)
          CONST = T.let([1, 2, 3].count(2) { |n| n > 2 }, Object)
          CONST = T.let('foo'.length, Object)
          CONST = T.let('foo'.size, Object)
        RUBY
      end
    end

    context "operators that produce unfrozen objects" do
      it "registers an offense when operating on a constant and a string" do
        expect_offense(<<~RUBY)
          CONST = T.let(FOO + 'bar', Object)
                        ^^^^^^^^^^^ Freeze mutable objects assigned to constants.
        RUBY

        expect_correction(<<~RUBY)
          CONST = T.let((FOO + 'bar').freeze, Object)
        RUBY
      end

      it "registers an offense when operating on multiple strings" do
        expect_offense(<<~RUBY)
          CONST = T.let('foo' + 'bar' + 'baz', Object)
                        ^^^^^^^^^^^^^^^^^^^^^ Freeze mutable objects assigned to constants.
        RUBY

        expect_correction(<<~RUBY)
          CONST = T.let(('foo' + 'bar' + 'baz').freeze, Object)
        RUBY
      end
    end

    context "when assigning an array without brackets" do
      it "does not insert brackets for %w() arrays" do
        expect_offense(<<~RUBY)
          XXX = T.let(%w(YYY ZZZ), Object)
                      ^^^^^^^^^^^ Freeze mutable objects assigned to constants.
        RUBY

        expect_correction(<<~RUBY)
          XXX = T.let(%w(YYY ZZZ).freeze, Object)
        RUBY
      end
    end

    it "freezes a heredoc" do
      expect_offense(<<~RUBY)
        FOO = T.let(<<-HERE, Object)
                    ^^^^^^^ Freeze mutable objects assigned to constants.
          SOMETHING
        HERE
      RUBY

      expect_correction(<<~RUBY)
        FOO = T.let(<<-HERE.freeze, Object)
          SOMETHING
        HERE
      RUBY
    end

    it_behaves_like "string literal"
  end
end
