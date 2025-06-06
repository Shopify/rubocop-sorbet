# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      module Signatures
        class CapitalizedTypeParametersTest < ::Minitest::Test
          MSG = "Sorbet/CapitalizedTypeParameters: Type parameters must be capitalized."

          def setup
            @cop = CapitalizedTypeParameters.new
          end

          def test_adds_offense_when_type_parameters_are_not_capitalized
            assert_offense(<<~RUBY)
              sig { type_parameters(:x).params(a: T.type_parameter(:x)).void }
                                    ^^ #{MSG}
                                                                   ^^ #{MSG}
              def foo(a)
                puts T.type_parameter(:x)
                                      ^^ Sorbet/CapitalizedTypeParameters: Type parameters must be capitalized.
              end

              sig do
                type_parameters(:foo, :Bar, :baz)
                                ^^^^ #{MSG}
                                            ^^^^ #{MSG}
                  .params(
                    a: T.type_parameter(:foo),
                                        ^^^^ #{MSG}
                    b: T.type_parameter(:Bar),
                    c: T.type_parameter(:baz),
                                        ^^^^ #{MSG}
                  ).void
              end
              def foo(a, b, c); end
            RUBY
          end

          def test_does_not_add_offense_when_type_parameters_are_capitalized
            assert_no_offenses(<<~RUBY)
              sig { type_parameters(:X).params(a: T.type_parameter(:X)).void }
              def foo(a); end

              sig do
                type_parameters(:Foo, :Bar, :Baz)
                  .params(
                    a: T.type_parameter(:Foo),
                    b: T.type_parameter(:Bar),
                    c: T.type_parameter(:Baz),
                  ).void
              end
              def foo(a, b, c); end
            RUBY
          end

          def test_autocorrects_type_parameters_to_capitalized
            assert_offense(<<~RUBY)
              sig { type_parameters(:x).params(a: T.type_parameter(:x)).void }
                                    ^^ #{MSG}
                                                                   ^^ #{MSG}
              def foo(a)
                puts T.type_parameter(:x)
                                      ^^ Sorbet/CapitalizedTypeParameters: Type parameters must be capitalized.
              end

              sig do
                type_parameters(:foo, :Bar, :baz)
                                ^^^^ #{MSG}
                                            ^^^^ #{MSG}
                  .params(
                    a: T.type_parameter(:foo),
                                        ^^^^ #{MSG}
                    b: T.type_parameter(:Bar),
                    c: T.type_parameter(:baz),
                                        ^^^^ #{MSG}
                  ).void
              end
              def foo(a, b, c); end
            RUBY

            assert_correction(<<~RUBY)
              sig { type_parameters(:X).params(a: T.type_parameter(:X)).void }
              def foo(a)
                puts T.type_parameter(:X)
              end

              sig do
                type_parameters(:Foo, :Bar, :Baz)
                  .params(
                    a: T.type_parameter(:Foo),
                    b: T.type_parameter(:Bar),
                    c: T.type_parameter(:Baz),
                  ).void
              end
              def foo(a, b, c); end
            RUBY
          end
        end
      end
    end
  end
end
