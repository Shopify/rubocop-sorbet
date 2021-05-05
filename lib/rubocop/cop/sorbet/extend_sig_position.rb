# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # This cop ensures that, if extend T::Sig is used in a class/module, it
      # is the first statement inside it.
      #
      # @example
      #
      #   # bad
      #   module Interface
      #     include Something
      #     extend T::Sig
      #   end
      #
      #   # good
      #   module Interface
      #     extend T::Sig
      #     include Something
      #   end
      class ExtendSigPosition < RuboCop::Cop::Cop
        include RangeHelp

        def_node_matcher :extend_t_sig?, <<~PATTERN
          (send nil? :extend (const (const nil? :T) :Sig))
        PATTERN

        def autocorrect(node)
          lambda do |corrector|
            corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))

            first_node = node.parent.child_nodes.first
            indentation = " " * first_node.loc.column
            corrector.insert_before(first_node, "#{node.source}\n#{indentation}")

            if processed_source[node.source_range.line - 2].empty? &&
              (processed_source[node.source_range.line].empty? || processed_source[node.source_range.line] == "end")
              corrector.remove(
                range_by_whole_lines(source_range(processed_source.buffer, node.source_range.line - 1, 0))
              )
            end
          end
        end

        def on_send(node)
          return unless extend_t_sig?(node)

          unless node.parent.child_nodes[0] == node
            add_offense(node, message: "extend T::Sig should be the first statement of a class/module")
          end
        end
      end
    end
  end
end
