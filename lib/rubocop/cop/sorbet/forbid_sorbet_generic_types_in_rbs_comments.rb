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

        def on_new_investigation
          processed_source.comments.each do |comment|
            next unless rbs_comment?(comment)

            comment.text.scan(SORBET_GENERIC_TYPE) do
              match = Regexp.last_match
              offense_range = comment.source_range.with(
                begin_pos: comment.source_range.begin_pos + match.begin(0),
                end_pos: comment.source_range.begin_pos + match.end(0),
              )
              message = format(MSG, sorbet_type: match[0], rbs_type: match[:rbs_type])

              add_offense(offense_range, message: message) do |corrector|
                corrector.replace(offense_range, match[:rbs_type])
              end
            end
          end
        end

        private

        def rbs_comment?(comment)
          comment.text.match?(::RuboCop::Sorbet::RBSParser::RBS_SIGNATURE_PREFIX) ||
            comment.text.match?(::RuboCop::Sorbet::RBSParser::RBS_CONTINUATION_PREFIX)
        end
      end
    end
  end
end
