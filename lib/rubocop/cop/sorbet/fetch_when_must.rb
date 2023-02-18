# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # rubocop:disable Lint/RedundantCopDisableDirective

      # Checks for `T.must(object[key])` and recommends `object.fetch(key)` instead.
      #
      # @safety
      #   False positives are possible if `object` does not respond to `fetch`,
      #   or if `Hash#default_proc` (or similar) is being used.
      #
      # @example
      #   # bad
      #   T.must(object[key])
      #
      #   # good
      #   object.fetch(key)
      #
      #   # good
      #   object[key]
      #
      #   # good
      #   # If `object` does not `respond_to? :fetch`, or if using `Hash` `default_proc`
      #   T.must(object[key]) # rubocop:disable Sorbet/FetchWhenMust
      #
      class FetchWhenMust < RuboCop::Cop::Base
        # rubocop:enable Lint/RedundantCopDisableDirective

        extend AutoCorrector
        include IgnoredNode

        MSG = "Use `%<expected>s` instead of `%<actual>s` when value must always be found, and receiver supports it."
        RESTRICT_ON_SEND = [:must].freeze

        # @!method t_must_on_index_result(node)
        def_node_matcher :t_must_on_index_result, <<~PATTERN
          (send
            (const { nil? cbase } :T) :must
            {
              (index $_ $_)
              (send $_ :[] $_)
            }
          )
        PATTERN

        def on_send(node)
          t_must_on_index_result(node) do |receiver, key|
            expected = "#{receiver.source}.fetch(#{key.source})"
            message = format(MSG, expected: expected, actual: node.source)

            add_offense(node, message: message) do |corrector|
              corrector.replace(node, expected) unless part_of_ignored_node?(node)
            end

            ignore_node(node)
          end
        end

        private

        def expected(receiver, key)
          "#{receiver.source}.fetch(#{key.source})"
        end
      end
    end
  end
end
