# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks for nested `T.must` calls and suggests to use
      # a single `T.must` around a conditional-send operator chain.
      #
      # @example
      #
      #    # bad
      #    T.must(T.must(A.b).c)
      #
      #    # bad
      #    T.must(T.must(T.must(A.b&.b).b).c)
      #
      #    # bad
      #    T.must(T.must(A.b)[:test])
      #
      #    # good
      #    T.must(A.b&.c)
      #
      #    # good
      #    T.must(A.b&.b&.b&.c)
      #
      #    # good
      #    T.must(A.b&.[](:test))
      #
      #    # good
      #    T.must(A.d(T.must(A.b&.c)))
      class ForbidNestedTMust < Base
        extend AutoCorrector
        include IgnoredNode

        MSG =
          "Please avoid nesting `T.must` calls, instead use a " \
            "single `T.must` around a conditional-send (`&.`) chain"

        def on_send(node)
          offender = nested_t_must?(node)
          return unless offender

          add_offense(node) do |corrector|
            next if part_of_ignored_node?(node)

            # We need to ensure conditional-send is used for the rest of the chain
            current_node = node.first_argument
            until fixed_t_must?((current_node = current_node.receiver))
              next if current_node.parent.safe_navigation?

              corrector.wrap(current_node, "", "&")
            end

            # Only add safe navigation when the receiver is not a T.must call
            safe_navigate = !fixed_t_must?(offender.first_argument)
            # And we don't have one already
            safe_navigate &&= !offender.parent.safe_navigation?
            safe_operator = safe_navigate ? "&" : ""

            if offender.parent.method?(:[])
              # Replace the `[...]` method call with a `&.[](...)` call
              corrector.replace(
                offender.parent,
                "#{offender.first_argument.source}#{safe_operator}.[](#{offender.parent.first_argument.source})",
              )
            else
              # Replace the `T.must` call with a conditional-send operator
              corrector.replace(offender, "#{offender.first_argument.source}#{safe_operator}")
            end
          end

          ignore_node(node)
        end

        # @!method fixed_t_must?(node)
        def_node_matcher :fixed_t_must?, <<~PATTERN
          (send (const nil? :T) :must ...)
        PATTERN

        # @!method t_must?(node)
        def_node_matcher :t_must?, <<~PATTERN
          (send (const nil? :T) :must %1)
        PATTERN

        # @!method recurse_into_first_branch?(node)
        def_node_matcher :recurse_into_first_branch?, <<~PATTERN
          { %1
          | ({send | csend} #recurse_into_first_branch?(%1) ...)
          }
        PATTERN

        # @!method nested_t_must?(node)
        def_node_matcher :nested_t_must?, <<~PATTERN
          #t_must?(
            #recurse_into_first_branch?(
              $#t_must?((...))
            )
          )
        PATTERN
      end
    end
  end
end
