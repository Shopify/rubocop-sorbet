# frozen_string_literal: true

require 'rubocop'
require_relative 'sorbet_sigil'

module RuboCop
  module Cop
    module Sorbet
      # This cop checks that every Ruby file contains a Sorbet sigil.
      #
      # @example
      #
      #  # bad
      #  # (start of file)
      #  class Foo; end
      #
      #  # good
      #  # (start of file)
      #  # typed: foo
      #
      #  # good
      #  # (start of file)
      #  # typed: true
      class MandatorySorbetSigil < RuboCop::Cop::Cop
        include SorbetSigil

        def investigate(processed_source)
          return if processed_source.tokens.empty?

          sorbet_sigil_line = sorbet_typed_sigil_comment(processed_source)
          return unless sorbet_sigil_line.nil?

          add_missing_sigil_offense(processed_source)
        end

        def autocorrect(_node)
          lambda do |corrector|
            return unless sorbet_typed_sigil_comment(processed_source).nil?

            token = processed_source.tokens.first
            corrector.insert_before(token.pos, "# typed: false\n")
          end
        end
      end
    end
  end
end
