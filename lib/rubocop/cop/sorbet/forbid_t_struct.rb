# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T::Struct`.
      #
      # `T::Struct` has runtime performance implications that can lead to around 5x slower code over the equivilant
      # PORO (plain old ruby object).
      #
      # @example
      #
      #   # bad
      #   class Foo < T::Struct
      #     prop :bar, T.nilable(String)
      #     const :baz, Integer
      #   end
      #
      #   # good
      #   class Foo
      #     extend T::Sig
      #
      #     sig { returns(T.nilable(String)) }
      #     attr_accessor :bar
      #
      #     sig { returns(Integer) }
      #     attr_reader :baz
      #   end
      class ForbidTStruct < RuboCop::Cop::Base
        MSG = "Do not use `T::Struct`."

        # @!method t_struct?(node)
        def_node_matcher(:t_struct?, <<~PATTERN)
          (const (const {nil? cbase} :T) :Struct)
        PATTERN

        def on_class(node)
          add_offense(node) if t_struct?(node.parent_class)
        end
      end
    end
  end
end
