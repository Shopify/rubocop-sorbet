# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class StructPropNameTest < ::Minitest::Test
        MSG = "Use snake_case for T::Struct property names."

        def setup
          @cop = target_cop.new(cop_config)
        end

        def test_registers_offenses_for_const_and_prop_names
          assert_offense(<<~RUBY)
            class User < T::Struct
              const :firstName, String
                    ^^^^^^^^^^ #{MSG}
              prop :lastName, String
                   ^^^^^^^^^ #{MSG}
              self.const :middleName, String
                         ^^^^^^^^^^^ #{MSG}
              self.prop :displayName, String
                        ^^^^^^^^^^^^ #{MSG}
              const :first_name, String
              prop :last_name, String
            end
          RUBY

          assert_no_corrections
        end

        def test_registers_offenses_for_all_t_struct_variants
          assert_offense(<<~RUBY)
            class User < T::ImmutableStruct
              const :firstName, String
                    ^^^^^^^^^^ #{MSG}
            end

            class Account < ::T::InexactStruct
              prop :accountId, Integer
                   ^^^^^^^^^^ #{MSG}
            end
          RUBY
        end

        def test_supports_camel_case
          @cop = target_cop.new(cop_config({ "EnforcedStyle" => "camelCase" }))

          assert_offense(<<~RUBY)
            class User < T::Struct
              const :first_name, String
                    ^^^^^^^^^^^ #{camel_case_msg}
              prop :last_name, String
                   ^^^^^^^^^^ #{camel_case_msg}
              const :firstName, String
              prop :lastName, String
            end
          RUBY
        end

        def test_allows_configured_patterns
          @cop = target_cop.new(cop_config({ "AllowedPatterns" => ["\\Alegacy[A-Z]"] }))

          assert_no_offenses(<<~RUBY)
            class User < T::Struct
              const :legacyName, String
            end
          RUBY
        end

        def test_rejects_forbidden_identifiers
          @cop = target_cop.new(cop_config({ "ForbiddenIdentifiers" => ["legacy_name"] }))

          assert_offense(<<~RUBY)
            class User < T::Struct
              const :legacy_name, String
                    ^^^^^^^^^^^^ #{forbidden_msg("legacy_name")}
            end
          RUBY
        end

        def test_rejects_forbidden_patterns
          @cop = target_cop.new(cop_config({ "ForbiddenPatterns" => ["_v1\\z"] }))

          assert_offense(<<~RUBY)
            class User < T::Struct
              const :name_v1, String
                    ^^^^^^^^ #{forbidden_msg("name_v1")}
            end
          RUBY
        end

        def test_allowed_patterns_take_precedence_over_forbidden_names
          @cop = target_cop.new(cop_config({
            "AllowedPatterns" => ["\\Alegacy_name\\z"],
            "ForbiddenIdentifiers" => ["legacy_name"],
          }))

          assert_no_offenses(<<~RUBY)
            class User < T::Struct
              const :legacy_name, String
            end
          RUBY
        end

        def test_ignores_names_that_are_not_symbol_literals
          assert_no_offenses(<<~RUBY)
            class User < T::Struct
              const "firstName", String
              prop property_name, String
              prop
            end
          RUBY
        end

        def test_ignores_calls_outside_t_structs
          assert_no_offenses(<<~RUBY)
            const :topLevelName, String

            class User
              const :firstName, String
              prop :lastName, String
            end
          RUBY
        end

        def test_ignores_calls_in_nested_lexical_scopes
          assert_no_offenses(<<~RUBY)
            class User < T::Struct
              def configure
                prop :methodName, String
              end

              class Profile
                prop :displayName, String
              end

              module Settings
                const :themeName, String
              end

              class << self
                prop :singletonName, String
              end
            end
          RUBY
        end

        def test_checks_nested_t_structs_independently
          assert_offense(<<~RUBY)
            class User < T::Struct
              class Profile < T::Struct
                const :displayName, String
                      ^^^^^^^^^^^^ #{MSG}
              end
            end
          RUBY
        end

        def test_checks_property_declarations_in_conditional_class_bodies
          assert_offense(<<~RUBY)
            class User < T::Struct
              if feature_enabled?
                const :displayName, String
                      ^^^^^^^^^^^^ #{MSG}
              end
            end
          RUBY
        end

        private

        def target_cop
          StructPropName
        end

        def camel_case_msg
          "Use camelCase for T::Struct property names."
        end

        def forbidden_msg(identifier)
          "`#{identifier}` is forbidden, use another property name instead."
        end
      end
    end
  end
end
