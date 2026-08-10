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
      end
    end
  end
end
