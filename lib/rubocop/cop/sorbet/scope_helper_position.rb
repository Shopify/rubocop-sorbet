# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # This cop ensures that helpers such as abstract!, interface! and final!
      # are invoke before any method definitions or invocations
      #
      # @example
      #
      #   # bad
      #   module Interface
      #     extend T::Sig
      #     extend T::Helpers
      #
      #     sig { returns(String) }
      #     def foo; end
      #
      #     interface!
      #   end
      #
      #   # good
      #   module Interface
      #     extend T::Sig
      #     extend T::Helpers
      #
      #     interface!
      #
      #     sig { returns(String) }
      #     def foo; end
      #   end
      class ScopeHelperPosition < RuboCop::Cop::Cop
        include RangeHelp
        HELPERS = %i(interface! abstract! final! sealed!).freeze
        ALLOWED_METHODS = %i(extend include).freeze

        def autocorrect(node)
          lambda do |corrector|
            corrector.remove(range_by_whole_lines(node.source_range, include_final_newline: true))

            if processed_source[node.source_range.line - 2].empty? &&
              (processed_source[node.source_range.line].empty? || processed_source[node.source_range.line] == "end")
              corrector.remove(
                range_by_whole_lines(source_range(processed_source.buffer, node.source_range.line - 1, 0))
              )
            end

            before_node = node.parent.each_child_node.find do |child_node|
              !ALLOWED_METHODS.include?(child_node.method_name)
            end

            indentation = " " * before_node.loc.column

            corrector.insert_before(before_node, "#{node.source}\n\n#{indentation}")
          end
        end

        def on_send(node)
          return unless HELPERS.include?(node.method_name)

          node.parent.each_child_node do |child_node|
            if !ALLOWED_METHODS.include?(child_node.method_name) && child_node.first_line < node.first_line
              add_offense(node, message: "Cannot invoke #{node.method_name} after method definitions or invocations")
              break
            end
          end
        end
      end
    end
  end
end
