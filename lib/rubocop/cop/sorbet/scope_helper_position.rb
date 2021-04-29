# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # This cop ensures that helpers such as abstract!, interface! and final!
      # are invoke before any method definitions
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

        def autocorrect(node)
          lambda do |corrector|
            end_pos = if processed_source[node.source_range.line].blank? &&
              processed_source[node.source_range.line - 2].blank?
              node.source_range.end_pos + 1
            else
              node.source_range.end_pos
            end

            range = range_between(node.source_range.begin_pos, end_pos)
            corrector.remove(range_by_whole_lines(range, include_final_newline: true))

            first_def = node.parent.each_child_node.find(&:def_type?)
            first_sig = node.parent.each_child_node.find { |child| child.method_name == :sig }
            before_node = first_sig && first_sig.first_line < first_def.first_line ? first_sig : first_def
            indentation = " " * before_node.loc.column

            corrector.insert_before(before_node, "#{node.source}\n\n#{indentation}")
          end
        end

        def on_send(node)
          return unless HELPERS.include?(node.method_name)

          node.parent.each_child_node do |child_node|
            if child_node.def_type? && child_node.first_line < node.first_line
              add_offense(node, message: "Cannot invoke #{node.method_name} after method definitions")
              break
            end
          end
        end
      end
    end
  end
end
