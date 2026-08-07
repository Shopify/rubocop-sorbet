# frozen_string_literal: true

require "rubocop"
require "rbi"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.bind` anywhere.
      # Set `AutocorrectToRBS: true` to replace supported calls with RBS inline comments.
      #
      # @example
      #
      #   # bad
      #   T.bind(self, Integer)
      #
      #   # good
      #   #: self as Integer
      class ForbidTBind < RuboCop::Cop::Base
        include RBSAssertionCorrection
        extend AutoCorrector

        MSG = "Do not use `T.bind`."
        RESTRICT_ON_SEND = [:bind].freeze

        # @!method t_bind?(node)
        def_node_matcher(:t_bind?, "(send (const {nil? cbase} :T) :bind _ _)")

        def on_send(node)
          return unless t_bind?(node)

          add_offense(node) { |corrector| autocorrect_t_bind_to_rbs(corrector, node) }
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect_t_bind_to_rbs(corrector, node)
          return unless node.first_argument&.self_type?
          return unless rbs_assertion_autocorrectable?(node)

          type = ::RBI::Type.parse_string(node.last_argument.source).rbs_string
          corrector.replace(node, "#: self as #{type}")
        rescue ::RBI::Type::Error
          nil
        end
      end
    end
  end
end
