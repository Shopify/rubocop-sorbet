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
      #   # good
      #   foo #: absurd
      class ForbidTAbsurd < RuboCop::Cop::Base
        include RBSAssertionCorrection
        extend AutoCorrector

        MSG = "Do not use `T.absurd`."
        RESTRICT_ON_SEND = [:absurd].freeze

        # @!method t_absurd?(node)
        def_node_matcher(:t_absurd?, "(send (const nil? :T) :absurd _)")

        def on_send(node)
          return unless t_absurd?(node)

          add_offense(node) { |corrector| autocorrect_t_absurd_to_rbs(corrector, node) }
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect_t_absurd_to_rbs(corrector, node)
          return unless rbs_assertion_autocorrectable?(node, allow_assignment: true)

          corrector.replace(node, "#{node.first_argument.source} #: absurd")
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
