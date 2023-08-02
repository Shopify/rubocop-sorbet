# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `.override(allow_incompatible: true)`.
      # Using `allow_incompatible` suggests a violation of the Liskov
      # Substitution Principle, meaning that a subclass is not a valid
      # subtype of its superclass. This Cop prevents these design smells
      # from occurring.
      #
      # @example
      #
      #   # bad
      #   sig.override(allow_incompatible: true)
      #
      #   # good
      #   sig.override
      class AllowIncompatibleOverride < RuboCop::Cop::Base
        MSG = "Usage of `allow_incompatible` suggests a violation of the Liskov Substitution Principle. " \
          "Instead, strive to write interfaces which respect subtyping principles and remove `allow_incompatible`"
        RESTRICT_ON_SEND = [:override].freeze

        # @!method allow_incompatible_override?(node)
        def_node_matcher(:allow_incompatible_override?, <<~PATTERN)
          (send
            #sig?
            :override
            (hash <$(pair (sym :allow_incompatible) true) ...>)
          )
        PATTERN

        # @!method sig?(node)
        def_node_search :sig?, <<~PATTERN
          (send _ :sig ...)
        PATTERN

        def on_send(node)
          allow_incompatible_override?(node) do |allow_incompatible_pair|
            add_offense(allow_incompatible_pair)
          end
        end
      end
    end
  end
end
