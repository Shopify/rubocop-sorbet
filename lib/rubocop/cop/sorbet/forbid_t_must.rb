# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.must` anywhere.
      # Set `AutocorrectToRBS: true` to replace supported calls with RBS inline comments.
      #
      # @example
      #
      #   # bad
      #   T.must(foo)
      #
      #   # good
      #   foo #: as !nil
      class ForbidTMust < RuboCop::Cop::Base
        include RBSAssertionCorrection
        extend AutoCorrector

        MSG = "Do not use `T.must`."
        RESTRICT_ON_SEND = [:must].freeze

        # @!method t_must?(node)
        def_node_matcher(:t_must?, "(send (const nil? :T) :must _)")

        def on_send(node)
          return unless t_must?(node)

          add_offense(node) { |corrector| autocorrect_t_must_to_rbs(corrector, node) }
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect_t_must_to_rbs(corrector, node)
          return if t_must?(node.first_argument)
          return unless rbs_assertion_autocorrectable?(node, allow_assignment: true)

          corrector.replace(node, "#{node.first_argument.source} #: as !nil")
        end
      end
    end
  end
end
