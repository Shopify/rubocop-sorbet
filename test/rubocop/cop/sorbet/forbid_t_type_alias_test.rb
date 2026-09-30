# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class ForbidTTypeAliasTest < ::Minitest::Test
        MSG = "Do not use `T.type_alias`."

        def setup
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => true))
        end

        def test_adds_offense_when_using_t_type_alias
          @cop = target_cop.new(cop_config("AutocorrectToRBS" => false))

          assert_offense(<<~RUBY)
            X = T.type_alias { T.any(String, Integer) }
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_no_corrections
        end

        def test_autocorrects_union_alias
          assert_offense(<<~RUBY)
            STRING_OR_INTEGER = T.type_alias { T.any(String, Integer) }
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
          RUBY

          assert_correction(<<~RUBY)
            #: type string_or_integer = (String | Integer)
          RUBY
        end

        def test_autocorrects_multiline_alias_in_lexical_scope
          assert_offense(<<~RUBY)
            module Types
              class Nested
                HTTPResponse = T.type_alias do
                               ^^^^^^^^^^^^^^^ #{MSG}
                  T::Hash[String, T.nilable(Integer)]
                end

                def call; end
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            module Types
              class Nested
                #: type http_response = Hash[String, Integer?]

                def call; end
              end
            end
          RUBY
        end

        def test_preserves_trailing_comment_and_indentation
          assert_offense(<<~RUBY)
            module Types
              # café
              MyType = T.type_alias { String } # explanation
                       ^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            module Types
              # café
              # explanation
              #: type my_type = String
            end
          RUBY
        end

        def test_does_not_correct_unsupported_contexts_or_types
          [
            "T.type_alias { String }",
            "value = T.type_alias { String }",
            "Other::MyType = T.type_alias { String }",
            "::MyType = T.type_alias { String }",
            "consume(MyType = T.type_alias { String })",
            "First = MyType = T.type_alias { String }",
            "MyType = T.type_alias { String }; consume",
            "consume; MyType = T.type_alias { String }",
            "MyType = T.type_alias { String } if condition",
            "class Foo; MyType = T.type_alias { String }; end",
            "MyType = T.type_alias { |arg| String }",
            "MyType = T.type_alias { }",
            "MyType = T.type_alias { build_type }",
            "MyType = T.type_alias { log; String }",
            "MyType = T.type_alias { String } #: Existing",
            "MyType = T.type_alias { String } #| Existing",
            "MyType = T.type_alias { String } # rubocop:disable Layout/LineLength",
          ].each do |source|
            start = source.index("T.type_alias")
            length = source.rindex("}") - start + 1
            assert_offense("#{source}\n#{" " * start}#{"^" * length} #{MSG}\n")
            assert_no_corrections
          end
        end

        def test_extracts_comments_inside_alias
          assert_offense(<<~RUBY)
            MyType = T.type_alias do
                     ^^^^^^^^^^^^^^^ #{MSG}
              # explanation
              String
            end
          RUBY

          assert_correction(<<~RUBY)
            # explanation
            #: type my_type = String
          RUBY
        end

        def test_does_not_move_directives_inside_alias
          assert_offense(<<~RUBY)
            MyType = T.type_alias do
                     ^^^^^^^^^^^^^^^ #{MSG}
              # rubocop:disable Layout/LineLength
              String
              # rubocop:enable Layout/LineLength
            end
          RUBY

          assert_no_corrections
        end

        def test_does_not_correct_conditional_declarations
          assert_offense(<<~RUBY)
            if condition
              MyType = T.type_alias { String }
                       ^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              consume
            end
          RUBY

          assert_no_corrections
        end

        private

        def target_cop
          ForbidTTypeAlias
        end
      end
    end
  end
end
