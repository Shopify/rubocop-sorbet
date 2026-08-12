# frozen_string_literal: true

require "rubocop"
require "rbi"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.cast` anywhere.
      # Set `AutocorrectToRBS: true` to replace supported calls with RBS inline comments.
      #
      # @example
      #
      #   # bad
      #   T.cast(foo, Integer)
      #
      #   # good
      #   foo #: as Integer
      class ForbidTCast < RuboCop::Cop::Base
        include RBSAssertionCorrection
        extend AutoCorrector

        MSG = "Do not use `T.cast`."
        RESTRICT_ON_SEND = [:cast].freeze

        # @!method t_cast?(node)
        def_node_matcher(:t_cast?, "(send (const nil? :T) :cast _ _)")

        def on_send(node)
          return unless t_cast?(node)

          add_offense(node) { |corrector| autocorrect_t_cast_to_rbs(corrector, node) }
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect_t_cast_to_rbs(corrector, node)
          return if t_cast?(node.first_argument)

          autocorrect_rbs_assertion(corrector, node, allow_assignment: true) do
            type = ::RBI::Type.parse_string(node.last_argument.source).rbs_string
            "#{node.first_argument.source} #: as #{type}"
          end
        rescue ::RBI::Type::Error
          nil
        end
      end
    end
  end
end
