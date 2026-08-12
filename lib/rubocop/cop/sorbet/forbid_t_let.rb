# frozen_string_literal: true

require "rubocop"
require "rbi"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.let` anywhere.
      # Set `AutocorrectToRBS: true` to replace supported calls with RBS inline comments.
      #
      # @example
      #
      #   # bad
      #   T.let(foo, Integer)
      #
      #   # good
      #   foo #: Integer
      class ForbidTLet < RuboCop::Cop::Base
        include RBSAssertionCorrection
        extend AutoCorrector

        MSG = "Do not use `T.let`."
        RESTRICT_ON_SEND = [:let].freeze

        # @!method t_let?(node)
        def_node_matcher(:t_let?, "(send (const nil? :T) :let _ _)")

        def on_send(node)
          return unless t_let?(node)

          add_offense(node) { |corrector| autocorrect_t_let_to_rbs(corrector, node) }
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect_t_let_to_rbs(corrector, node)
          return if t_let?(node.first_argument)

          autocorrect_rbs_assertion(corrector, node, allow_assignment: true) do
            type = ::RBI::Type.parse_string(node.last_argument.source).rbs_string
            [node.first_argument.source, type]
          end
        rescue ::RBI::Type::Error
          nil
        end
      end
    end
  end
end
