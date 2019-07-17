# frozen_string_literal: true

require 'rubocop'

module RuboCop
  module Cop
    module Sorbet
      # This cop checks that every Ruby file contains a valid Sorbet sigil.
      # Adapted from: https://gist.github.com/clarkdave/85aca4e16f33fd52aceb6a0a29936e52
      #
      # @example RequireSigilOnAllFiles: false (default)
      #
      #  # bad
      #  # (start of file)
      #  # typed: no
      #
      #  # good
      #  # (start of file)
      #  class Foo; end
      #
      #  # good
      #  # (start of file)
      #  # typed: true
      #
      # @example RequireSigilOnAllFiles: true
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

          sorbet_sigil_line = sorbet_typed_sigil_comment(processed_source)

          if sorbet_sigil_line.nil?
            token = processed_source.tokens.first

            if require_sorbet_sigil_on_all_files?
              add_offense(
                token,
                location: token.pos,
                message: 'No Sorbet sigil found in file. ' \
                  'Try a `typed: false` to start (you can also use `rubocop -a` to automatically add this).'
              )
            end
          else
            strictness = sorbet_typed_strictness(sorbet_sigil_line)
            return if valid_sorbet_strictness?(strictness)

            add_offense(
              sorbet_sigil_line,
              location: sorbet_sigil_line.pos,
              message: "Invalid Sorbet sigil `#{strictness}`."
            )
          end
        end

        def autocorrect(_node)
          lambda do |corrector|
            return unless require_sorbet_sigil_on_all_files?
            return unless sorbet_typed_sigil_comment(processed_source).nil?

            token = processed_source.tokens.first

            corrector.insert_before(token.pos, "# typed: false\n")
          end
        end

        private

        def require_sorbet_sigil_on_all_files?
          !!cop_config['RequireSigilOnAllFiles']
        end

        SORBET_SIGIL_REGEX = /#\s+typed:\s+([\w]+)/

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
