# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Sigils
        class EnforceSigilOrderTest < ::Minitest::Test
          MSG = "Sorbet/EnforceSigilOrder: Magic comments should be in the following order: encoding, typed, warn_indent, frozen_string_literal."

          def setup
            @cop = EnforceSigilOrder.new
          end

          def test_makes_no_offense_on_empty_files
            assert_no_offenses("")
          end

          def test_makes_no_offense_with_no_magic_comments
            assert_no_offenses(<<~RUBY)
              class Foo; end
            RUBY
          end

          def test_makes_no_offense_with_random_magic_comments
            assert_no_offenses(<<~RUBY)
              # foo: 1
              # bar: true
              # baz: "Hello, World"
              class Foo; end
            RUBY
          end

          def test_makes_no_offense_with_only_one_magic_comment
            assert_no_offenses(<<~RUBY)
              # typed: true
              class Foo; end
            RUBY
          end

          def test_makes_no_offense_when_the_magic_comments_are_correctly_ordered
            assert_no_offenses(<<~RUBY)
              # encoding: utf-8
              # coding: utf-8
              # typed: true
              # warn_indent: true
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_makes_no_offense_when_the_magic_comments_are_correctly_ordered_with_random_comments_in_the_middle
            assert_no_offenses(<<~RUBY)
              # coding: utf-8
              # typed: true
              # foo: 1
              # bar: true
              # frozen_string_literal: true
              # baz: "Hello, World"
              class Foo; end
            RUBY
          end

          def test_makes_offense_when_two_magic_comments_are_not_correctly_ordered
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_makes_offense_when_all_magic_comments_are_not_correctly_ordered
            assert_offense(<<~RUBY)
              # encoding: utf-8
              ^^^^^^^^^^^^^^^^^ #{MSG}
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # warn_indent: true
              ^^^^^^^^^^^^^^^^^^^ #{MSG}
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              # coding: utf-8
              ^^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
          end

          def test_autocorrects_two_magic_comments_in_the_correct_order
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # typed: true
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_autocorrects_all_magic_comments_in_the_correct_order
            assert_offense(<<~RUBY)
              # encoding: utf-8
              ^^^^^^^^^^^^^^^^^ #{MSG}
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # warn_indent: true
              ^^^^^^^^^^^^^^^^^^^ #{MSG}
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              # coding: utf-8
              ^^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # encoding: utf-8
              # coding: utf-8
              # typed: true
              # warn_indent: true
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_autocorrects_all_magic_comments_in_the_correct_order_even_with_random_comments_in_the_middle
            assert_offense(<<~RUBY)
              # encoding: utf-8
              ^^^^^^^^^^^^^^^^^ #{MSG}
              # foo
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # bar: true
              # warn_indent: true
              ^^^^^^^^^^^^^^^^^^^ #{MSG}
              # baz: "Hello"
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              # coding: utf-8
              ^^^^^^^^^^^^^^^ #{MSG}
              # another foo
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # encoding: utf-8
              # foo
              # coding: utf-8
              # bar: true
              # typed: true
              # baz: "Hello"
              # warn_indent: true
              # frozen_string_literal: true
              # another foo
              class Foo; end
            RUBY
          end

          def test_autocorrects_magic_comments_while_removing_blank_lines
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}

              # typed: true
              ^^^^^^^^^^^^^ #{MSG}


              # encoding: utf-8
              ^^^^^^^^^^^^^^^^^ #{MSG}
              class Foo; end
            RUBY
            assert_correction(<<~RUBY)
              # encoding: utf-8
              # typed: true
              # frozen_string_literal: true
              class Foo; end
            RUBY
          end

          def test_autocorrects_magic_comments_while_removing_blank_lines_and_preserving_other_blank_lines
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              # encoding: utf-8
              ^^^^^^^^^^^^^^^^^ #{MSG}

              class Foo; end


            RUBY

            assert_correction(<<~RUBY)
              # encoding: utf-8
              # typed: true
              # frozen_string_literal: true

              class Foo; end


            RUBY
          end

          def test_autocorrects_magic_comments_while_preserving_comments
            assert_offense(<<~RUBY)
              # frozen_string_literal: true
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              #
              # typed: true
              ^^^^^^^^^^^^^ #{MSG}
              #
              # encoding: utf-8
              ^^^^^^^^^^^^^^^^^ #{MSG}
              #
              class Foo; end
              #
            RUBY
            assert_correction(<<~RUBY)
              # encoding: utf-8
              #
              # typed: true
              #
              # frozen_string_literal: true
              #
              class Foo; end
              #
            RUBY
          end
        end
      end
    end
  end
end
