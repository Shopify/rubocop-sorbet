# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks that `T::Struct` property names use the configured style.
      # The supported styles and name filters match `Naming/MethodName`.
      #
      # @example EnforcedStyle: snake_case (default)
      #   # bad
      #   class User < T::Struct
      #     const :firstName, String
      #     prop :lastName, String
      #   end
      #
      #   # good
      #   class User < T::Struct
      #     const :first_name, String
      #     prop :last_name, String
      #   end
      #
      # @example EnforcedStyle: camelCase
      #   # bad
      #   class User < T::Struct
      #     const :first_name, String
      #     prop :last_name, String
      #   end
      #
      #   # good
      #   class User < T::Struct
      #     const :firstName, String
      #     prop :lastName, String
      #   end
      #
      # @example AllowedPatterns: ['\Alegacy[A-Z]']
      #   # good
      #   class User < T::Struct
      #     const :legacyName, String
      #   end
      #
      # @example ForbiddenIdentifiers: ['legacy_name']
      #   # bad
      #   class User < T::Struct
      #     const :legacy_name, String
      #   end
      #
      # @example ForbiddenPatterns: ['_v1\z']
      #   # bad
      #   class User < T::Struct
      #     const :name_v1, String
      #   end
      class StructPropName < Base
        include AllowedPattern
        include ConfigurableNaming
        include ForbiddenIdentifiers
        include ForbiddenPattern

        MSG = "Use %<style>s for T::Struct property names."
        MSG_FORBIDDEN = "`%<identifier>s` is forbidden, use another property name instead."

        RESTRICT_ON_SEND = [:const, :prop].freeze

        # @!method t_struct?(node)
        def_node_matcher :t_struct?, <<~PATTERN
          (const (const {nil? cbase} :T) {:Struct :ImmutableStruct :InexactStruct})
        PATTERN

        def on_send(node)
          name_node = node.first_argument
          receiver = node.receiver
          return unless (receiver.nil? || receiver.self_type?) && name_node&.sym_type? && within_t_struct?(node)

          name = name_node.value
          return if matches_allowed_pattern?(name)

          if forbidden_name?(name)
            add_offense(name_node, message: format(MSG_FORBIDDEN, identifier: name))
          else
            check_name(node, name, name_node)
          end
        end

        private

        def within_t_struct?(node)
          scope = node.each_ancestor(:class, :module, :sclass, :any_def).first

          scope&.class_type? && t_struct?(scope.parent_class)
        end

        def forbidden_name?(name)
          forbidden_identifier?(name) || forbidden_pattern?(name)
        end

        def message(style)
          format(MSG, style: style)
        end
      end
    end
  end
end
