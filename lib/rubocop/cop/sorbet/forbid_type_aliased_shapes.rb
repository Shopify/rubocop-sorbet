# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows defining type aliases that contain shapes
      #
      # @example
      #
      #  # bad
      #  Foo = T.type_alias { { foo: Integer } }
      #
      #  # good
      #  class Foo
      #    extend T::Sig
      #
      #    sig { params(foo: Integer).void }
      #    def initialize(foo)
      #      @foo = foo
      #    end
      #  end
      class ForbidTypeAliasedShapes < RuboCop::Cop::Base
        MSG = "Type aliases shouldn't contain shapes because of significant performance overhead"

        # @!method type_alias?(node)
        def_node_matcher(:type_alias?, <<-PATTERN)
          (block
            (send
              (const nil? :T) :type_alias)
            (args)
            (hash ...)
          )

        PATTERN

        def on_block(node)
          add_offense(node) if type_alias?(node)
        end

        alias_method :on_numblock, :on_block
      end
    end
  end
end
