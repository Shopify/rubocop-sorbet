# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module Sorbet
      # This cop checks that every Ruby file contains a valid Sorbet sigil.
      # Adapted from: https://gist.github.com/clarkdave/85aca4e16f33fd52aceb6a0a29936e52
      #
      # @example
      #
      #  # bad
      #  # (start of file)
      #  class Foo; end
      #
      #  # bad
      #  # (start of file)
      #  # typed: no
      #
      #  # good
      #  # (start of file)
      #  # typed: true
      class ValidSorbetSigil < RuboCop::Cop::Cop
        def investigate(processed_source)
          return if processed_source.tokens.empty?

          strictness = sorbet_typed_strictness(processed_source.raw_source)
          return if valid_sorbet_strictness?(strictness)

          if strictness.nil?
            token = processed_source.tokens.first

            add_offense(
              token,
              location: token.pos,
              message: 'No Sorbet sigil found in file. ' \
                'Try a `typed: false` to start (you can also use `rubocop -a` to automatically add this).'
            )
          else
            token = sorbet_typed_sigil_comment(processed_source)

            add_offense(
              token,
              location: token.pos,
              message: "Invalid Sorbet sigil #{strictness}."
            )
          end
        end

        def autocorrect(_node)
          lambda do |corrector|
            return unless sorbet_typed_strictness(processed_source.raw_source).nil?

            token = processed_source.tokens.first

            corrector.insert_before(token.pos, "# typed: false\n")
          end
        end

        private

        def sorbet_typed_sigil_comment(processed_source)
          processed_source.find_token do |token|
            /#\s+typed:\s+([\w]+)/.match?(token.text)
          end
        end

        def valid_sorbet_strictness?(strictness)
          %w(ignore false true strict strong).include?(strictness)
        end

        def sorbet_typed_strictness(raw_source)
          raw_source.match(/\A(?:#[^\n]*\n)*#\s+typed:\s+([\w]+)/)&.captures&.first
        end
      end
    end
  end
end
