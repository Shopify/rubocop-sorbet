# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # This cop disallows using `T.untyped` anywhere.
      #
      # @example
      #
      #   # bad
      #   T.untyped(foo)
      #
      #   # good
      #   foo
      class ForbidTUntyped < RuboCop::Cop::Cop
        def_node_matcher(:t_untyped?, "(send (const nil? :T) :untyped)")

        def on_send(node)
          add_offense(node, message: "Do not use `T.untyped`.") if t_untyped?(node)
        end
      end
    end
  end
end
