# frozen_string_literal: true

require 'rubocop'
require_relative 'sorbet_sigil'

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
        include SorbetSigil

        def investigate(processed_source)
          return if processed_source.tokens.empty?

          sorbet_sigil_line = sorbet_typed_sigil_comment(processed_source)

          if sorbet_sigil_line.nil?
            if require_sorbet_sigil_on_all_files?
              add_missing_sigil_offense(processed_source)
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
      end
    end
  end
end
