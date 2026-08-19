# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.absurd` anywhere.
      # Set `AutocorrectToRBS: true` to replace supported calls with RBS inline comments.
      #
      # @example
      #
      #   # bad
      #   T.absurd(foo)
      #
      #   # good (Sorbet before 0.6.99999)
      #   foo #: absurd
      #
      #   # good (Sorbet 0.6.99999 and later)
      #   raise #: absurd(foo)
      class ForbidTAbsurd < RuboCop::Cop::Base
        include RBSAssertionCorrection
        include TargetSorbetVersion
        extend AutoCorrector

        MSG = "Do not use `T.absurd`."
        RESTRICT_ON_SEND = [:absurd].freeze

        # TODO: Replace with the real release version once https://github.com/Shopify/sorbet/pull/871 lands.
        MINIMUM_RBS_ABSURD_VERSION = "0.6.99999"
        SUPPORTED_ABSURD_VARIABLE_TYPES = [:lvar, :ivar, :cvar, :gvar, :self].freeze

        minimum_target_sorbet_static_version MINIMUM_RBS_ABSURD_VERSION

        # @!method t_absurd?(node)
        def_node_matcher(:t_absurd?, "(send (const nil? :T) :absurd _)")

        def on_send(node)
          return unless t_absurd?(node)

          add_offense(node) { |corrector| autocorrect_t_absurd_to_rbs(corrector, node) }
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect_t_absurd_to_rbs(corrector, node)
          argument = node.first_argument

          if enabled_for_sorbet_static_version?
            autocorrect_new_rbs_absurd(corrector, node, argument)
          else
            autocorrect_legacy_rbs_absurd(corrector, node, argument)
          end
        end

        def autocorrect_new_rbs_absurd(corrector, node, argument)
          return unless rbs_assertion_autocorrectable?(node)
          return unless SUPPORTED_ABSURD_VARIABLE_TYPES.include?(argument.type)

          corrector.replace(node, "raise #: absurd(#{argument.source})")
        end

        def autocorrect_legacy_rbs_absurd(corrector, node, argument)
          return unless rbs_assertion_autocorrectable?(node, allow_assignment: true)

          corrector.replace(node, "#{argument.source} #: absurd")
        end

        def assertion_statement(node, allow_assignment:)
          inline_else = inline_else_statement(node)
          return super(inline_else, allow_assignment: allow_assignment) if inline_else

          super
        end

        def inline_else_statement(node)
          parent = node.parent
          return unless parent&.type?(:case, :if)
          return unless inline_else_branch(parent).equal?(node)

          else_range = parent.loc.else
          parent if else_range&.source == "else" && else_range.line == node.first_line
        end

        # `unless` is represented as an `if` node with its branches swapped, so its source
        # `else` branch is the second child. For `if` and `case`, it is the last child.
        def inline_else_branch(parent)
          return parent.children.last unless parent.if_type? && parent.keyword == "unless"

          parent.children[1]
        end
      end
    end
  end
end
