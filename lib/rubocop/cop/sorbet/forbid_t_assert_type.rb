# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.assert_type!` anywhere.
      #
      # @example
      #
      #   # bad
      #   T.assert_type!(foo, Integer)
      #
      #   # good
      #   raise unless foo.is_a?(Integer)
      #
      #   # good
      #   assert_kind_of(Integer, foo)
      class ForbidTAssertType < RuboCop::Cop::Base
        MSG = "Do not use `T.assert_type!`."
        RESTRICT_ON_SEND = [:assert_type!].freeze

        # @!method t_assert_type?(node)
        def_node_matcher(:t_assert_type?, "(call (const {nil? cbase} :T) :assert_type! ...)")

        def on_send(node)
          add_offense(node) if t_assert_type?(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
