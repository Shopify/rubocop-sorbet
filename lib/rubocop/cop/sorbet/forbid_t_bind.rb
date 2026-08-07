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
        include RangeHelp
        extend AutoCorrector

        MSG = "Do not use `T.bind`."
        LINE_ENDINGS = ["", "\n", "\r", "#"].freeze
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
          return unless cop_config["AutocorrectToRBS"]
          return unless autocorrectable_t_bind?(node)

          type = ::RBI::Type.parse_string(node.last_argument.source).rbs_string
          corrector.replace(node, "#: self as #{type}")
        rescue ::RBI::Type::Error
          nil
        end

        def autocorrectable_t_bind?(node)
          return false unless node.first_argument&.self_type?
          return false unless assertion_ends_line?(node)
          return false if ::RuboCop::Sorbet::RBSParser.rbs_annotation_after(processed_source, node)

          node.source_range.source_line.index(/\S/) == node.source_range.column
        end

        def assertion_ends_line?(node)
          LINE_ENDINGS.include?(source_after_horizontal_whitespace(node))
        end

        def source_after_horizontal_whitespace(node, length: 1)
          range = range_with_surrounding_space(node.source_range, side: :right, newlines: false)
          range.source_buffer.source[range.end_pos, length]
        end
      end
    end
  end
end
