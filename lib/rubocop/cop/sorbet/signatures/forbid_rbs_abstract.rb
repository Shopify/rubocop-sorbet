# frozen_string_literal: true

require "stringio"

module RuboCop
  module Cop
    module Sorbet
      # Forbids usage of the `@abstract` annotation with RBS signatures.
      #
      # Good:
      #
      # ```
      # #: -> void
      # def foo; end
      # ```
      #
      # Bad:
      #
      # ```
      # # @abstract
      # #: -> void
      # def foo; end
      # ```
      class ForbidRBSAbstract < ::RuboCop::Cop::Base
        include RBSHelp

        MSG = "Do not use `@abstract`."

        def on_def(node)
          check_annotation(node)
        end

        def on_defs(node)
          check_annotation(node)
        end

        private

        def check_annotation(node)
          # We only register offenses if the node has an RBS signature
          comments = preceeding_comments(node)
          return unless comments.any? { |comment| rbs_comment?(comment) }

          # We only register offenses if the node has an @abstract annotation
          comment = comments.find { |comment| comment.text.match?(/\A#\s*@abstract\z/) }
          return unless comment

          add_offense(comment)
        end
      end
    end
  end
end
