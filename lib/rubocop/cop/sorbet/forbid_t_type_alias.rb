# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.type_alias` anywhere.
      #
      # @example
      #
      #   # bad
      #   STRING_OR_INTEGER = T.type_alias { T.any(Integer, String) }
      #
      #   # good
      #   #: type string_or_integer = Integer | String
      class ForbidTTypeAlias < RuboCop::Cop::Base
        MSG = "Do not use `T.type_alias`."
        RESTRICT_ON_SEND = [:type_alias].freeze

        # @!method t_type_alias?(node)
        def_node_matcher(:t_type_alias?, "(call (const {nil? cbase} :T) :type_alias ...)")

        def on_send(node)
          return unless t_type_alias?(node)

          parent = node.parent
          location = parent&.type?(:block, :numblock) && parent.send_node == node ? parent : node
          add_offense(location)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
