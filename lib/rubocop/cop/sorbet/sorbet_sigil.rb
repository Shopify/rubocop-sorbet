# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module Sorbet
      # Shared methods relateds to sigils validation
      module SorbetSigil
        protected

        SORBET_SIGIL_REGEX = /#\s+typed:\s+([\w]+)/

        def add_missing_sigil_offense(processed_source)
          token = processed_source.tokens.first

          add_offense(
            token,
            location: token.pos,
            message: 'No Sorbet sigil found in file. ' \
              'Try a `typed: false` to start (you can also use `rubocop -a` to automatically add this).'
          )
        end

        def sorbet_typed_sigil_comment(processed_source)
          processed_source.tokens
            .take_while { |token| token.type == :tCOMMENT }
            .find { |token| SORBET_SIGIL_REGEX.match?(token.text) }
        end

        def valid_sorbet_strictness?(strictness)
          %w(ignore false true strict strong).include?(strictness)
        end

        def sorbet_typed_strictness(sigil_line)
          sigil_line.text.match(SORBET_SIGIL_REGEX)&.captures&.first
        end
      end
    end
  end
end
