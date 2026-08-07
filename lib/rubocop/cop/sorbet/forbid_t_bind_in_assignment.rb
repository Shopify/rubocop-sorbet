# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows assigning the result of `T.bind`.
      #
      # `T.bind` changes the type of its first argument and returns that argument.
      # Assigning its result can therefore unintentionally change the inferred type
      # of both the assignment target and the first argument.
      #
      # @safety
      #   Auto-correction is unsafe because replacing `T.bind` with `T.cast`
      #   removes the scope-wide type rebind of the first argument. Code that
      #   relies on that narrowed type may no longer type-check.
      #
      # @example
      #
      #   # bad
      #   foo = T.bind(self, Integer)
      #
      #   # good
      #   foo = T.cast(self, Integer)
      class ForbidTBindInAssignment < RuboCop::Cop::Base
        extend AutoCorrector
        MSG = "Do not assign the result of `T.bind`; it also changes the type of its first argument."
        RESTRICT_ON_SEND = [:bind].freeze

        # @!method t_bind?(node)
        def_node_matcher(:t_bind?, "(send (const nil? :T) :bind _ _)")

        def on_send(node)
          parent = node.parent
          return unless t_bind?(node) && parent&.assignment? && parent.children.last.equal?(node)

          add_offense(node) do |corrector|
            corrector.replace(node.loc.selector, "cast")
          end
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
