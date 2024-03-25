# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks for the ordering of keyword arguments required by
      # sorbet-runtime. The ordering requires that all keyword arguments
      # are at the end of the parameters list, and all keyword arguments
      # with a default value must be after those without default values.
      #
      # @example
      #
      #   # bad
      #   sig { params(a: Integer, b: String).void }
      #   def foo(a: 1, b:); end
      #
      #   # good
      #   sig { params(b: String, a: Integer).void }
      #   def foo(b:, a: 1); end
      class KeywordArgumentOrdering < ::RuboCop::Cop::Base
        include SignatureHelp

        MSG = "Optional keyword arguments must be at the end of the parameter list."

        def on_signed_def(node)
          kwoptargs = []
          last_kwarg = nil

          node.arguments.each do |arg|
            if arg.kwoptarg_type?
              kwoptargs << arg
              next
            elsif arg.kwarg_type?
              last_kwarg = arg
              next
            end
          end

          return if last_kwarg.nil?

          kwoptargs.each do |kwoptarg|
            add_offense(kwoptarg) if kwoptarg.sibling_index < last_kwarg.sibling_index
          end
        end
        alias_method :on_signed_defs, :on_signed_def
      end
    end
  end
end
