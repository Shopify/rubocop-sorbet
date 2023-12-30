# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Disallows the usage of `.void.checked(:tests)`.
      #
      # Using `.void` changes the value returned from the method, but only if
      # runtime type checking is enabled for the method. Methods marked `.void`
      # will return different values in tests compared with non-test
      # environments. This is particularly troublesome if branching on the
      # result of a `.void` method, because the returned value in test code
      # will be the truthy `VOID` value, while the non-test return value may be
      # falsy depending on the method's implementation.
      #
      # - Use `.returns(T.anything).checked(:tests)` to keep the runtime type
      #   checking for the rest of the parameters.
      # - Use `.void.checked(:never)` if you are on an older version of Sorbet
      #   which does not have `T.anything` (meaning versions 0.5.10781 or
      #   earlier. Versions released after 2023-04-14 include `T.anything`.)
      #
      # @example
      #
      #   # bad
      #   sig { void.checked(:tests) }
      #
      #   # good
      #   sig { void }
      #   sig { returns(T.anything).checked(:tests) }
      #   sig { void.checked(:never) }
      class VoidCheckedTests < ::RuboCop::Cop::Base
        include(RuboCop::Cop::RangeHelp)
        include(RuboCop::Cop::Sorbet::SignatureHelp)
        extend AutoCorrector

        # @!method checked_tests(node)
        def_node_search(:checked_tests, <<~PATTERN)
          (send _ :checked (sym :tests))
        PATTERN

        MESSAGE =
          "The return value in a `.void.checked(:tests)` makes test behavior " \
            "diffferent from non-test behavior. Either use " \
            "`.returns(T.anything).checked(:tests)` to keep checking in tests, " \
            "or `.void.checked(:never)` to leave the return completely untouched."
        private_constant(:MESSAGE)

        private def top_level_void(node)
          return nil unless node.is_a?(RuboCop::AST::SendNode)

          if node.method_name == :void
            node
          else
            top_level_void(node.receiver)
          end
        end

        def on_signature(node)
          checked_send = checked_tests(node).first
          return unless checked_send

          _recv, _block_args, body = *node
          void_send = top_level_void(body)

          return unless void_send

          add_offense(
            void_send.selector,
            message: MESSAGE,
          ) do |corrector|
            corrector.replace(void_send.selector, "returns(T.anything)")
          end
        end
      end
    end
  end
end
