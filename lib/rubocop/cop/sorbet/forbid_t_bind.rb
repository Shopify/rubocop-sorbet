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
        extend AutoCorrector

        MSG = "Do not use `T.bind`."
        COMMENT_START = "#"
        HORIZONTAL_WHITESPACE = ["\t", " "].freeze
        NEWLINES = ["\n", "\r"].freeze
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
          return false if rbs_annotation_follows?(node)

          node.source_range.source_line.index(/\S/) == node.source_range.column
        end

        def assertion_ends_line?(node)
          source = processed_source.buffer.source
          position = skip_horizontal_whitespace(source, node.source_range.end_pos)
          character = source[position]

          character.nil? || NEWLINES.include?(character) || character == COMMENT_START
        end

        def rbs_annotation_follows?(node)
          source = processed_source.buffer.source
          position = skip_horizontal_whitespace(source, node.source_range.end_pos)

          source[position, 2] == "#:"
        end

        def skip_horizontal_whitespace(source, position)
          position += 1 while HORIZONTAL_WHITESPACE.include?(source[position])
          position
        end
      end
    end
  end
end
