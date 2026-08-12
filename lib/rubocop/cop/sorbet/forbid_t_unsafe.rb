# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.unsafe` anywhere.
      # Set `AutocorrectToRBS: true` to replace supported calls with RBS inline comments.
      #
      # @example
      #
      #   # bad
      #   T.unsafe(foo)
      #
      #   # good
      #   foo #: as untyped
      class ForbidTUnsafe < RuboCop::Cop::Base
        include RBSAssertionCorrection
        extend AutoCorrector

        MSG = "Do not use `T.unsafe`."
        RESTRICT_ON_SEND = [:unsafe].freeze

        # @!method t_unsafe?(node)
        def_node_matcher(:t_unsafe?, "(send (const nil? :T) :unsafe _)")

        def on_send(node)
          return unless t_unsafe?(node)

          add_offense(node) { |corrector| autocorrect_t_unsafe_to_rbs(corrector, node) }
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect_t_unsafe_to_rbs(corrector, node)
          autocorrect_rbs_assertion(corrector, node, allow_assignment: true) do
            "#{node.first_argument.source} #: as untyped"
          end
        end
      end
    end
  end
end
