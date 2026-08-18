# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Forbids Sorbet's `T::` generic types in RBS comments.
      #
      # @example
      #
      #   # bad
      #   #: (T::Array[String]) -> ::T::Hash[Symbol, Integer]
      #
      #   # good
      #   #: (Array[String]) -> Hash[Symbol, Integer]
      class ForbidSorbetGenericTypesInRBSComments < Base
        extend AutoCorrector

        MSG = "Use `%<rbs_type>s` instead of Sorbet's `%<sorbet_type>s` in RBS comments."

        RBS_GENERICS = [
          "Array",
          "Class",
          "Enumerable",
          "Enumerator",
          "Enumerator::Chain",
          "Enumerator::Lazy",
          "Hash",
          "Module",
          "Range",
          "Set",
        ].freeze

        CONSTANT_NAME = :tUIDENT
        NAMESPACE_SEPARATOR = :pCOLON2
        ARG_BRACKET = :pLBRACKET

        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless ::RuboCop::Sorbet::RBSParser.rbs_comment?(comment)

            report_sorbet_generic(comment) do |offense_range, rbs_type|
              message = format(MSG, sorbet_type: offense_range.source, rbs_type:)

              add_offense(offense_range, message:) do |corrector|
                corrector.replace(offense_range, rbs_type)
              end
            end
          end
        end

        private

        def report_sorbet_generic(comment)
          types(comment).each do |type_tokens|
            type_values = type_tokens.map(&:value)
            type_values = type_values[1..] if type_values.first == "::"
            next unless type_values in ["T", "::", *name, "["]

            rbs_type = name.join # ex. `Array`, `Enumerator::Lazy`
            next unless RBS_GENERICS.include?(rbs_type)

            sorbet_type = type_tokens[...-1] # drops `[`
            yield offense_range(comment, sorbet_type), rbs_type
          end
        end

        # Group tokens into types, keeping the opening bracket
        # when the type has arguments `[ `T`, `::`, `Array`, `[` ]`
        def types(comment)
          ::RuboCop::Sorbet::RBSParser.rbs_tokens(comment).chunk_while do |left, right|
            part_of_type?(left) && (part_of_type?(right) || right.type == ARG_BRACKET)
          end
        end

        def part_of_type?(token)
          token.type == CONSTANT_NAME || token.type == NAMESPACE_SEPARATOR
        end

        def offense_range(comment, type)
          comment_start_pos = comment.source_range.begin_pos
          type_start_pos = type.first.location.start_pos
          type_end_pos = type.last.location.end_pos

          comment.source_range.with(
            begin_pos: comment_start_pos + type_start_pos,
            end_pos: comment_start_pos + type_end_pos,
          )
        end
      end
    end
  end
end
