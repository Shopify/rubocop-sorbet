# frozen_string_literal: true

require_relative "../../sorbet_from_contract_service.rb"
module RuboCop
  module Cop
    module Sorbet
      class PreferSorbetOverContracts < Cop
        MSG = "Instead of Contracts use Sorbet signatures."

        def_node_matcher :contract_statement, <<-PATTERN
          (send _ :Contract ...)
        PATTERN

        def on_send(node)
          contract_statement(node) do |statement|
            add_offense(node, message: format(MSG, statement: statement))
          end
        end

        CONTRACT_PATTERN = NodePattern.new("$(send _ :Contract $... (:hash (:pair $_ $_)))")
        SHORTHAND_CONTRACT_PATTERN = NodePattern.new("$(send _ :Contract $_)")
        EXTEND_T_SIG_PATTERN = NodePattern.new("(send _ :extend (const (const _ :T) :Sig))")

        def autocorrect(node)
          if CONTRACT_PATTERN.match(node)
            convert_contract_multi_args(node)
          elsif SHORTHAND_CONTRACT_PATTERN.match(node)
            convert_shorthand_contract(node)
          end
        end

        def convert_shorthand_contract(node)
          full_source, ret = SHORTHAND_CONTRACT_PATTERN.match(node)
          convert_node(node, full_source, [], ret)
        end

        def convert_contract_multi_args(node)
          full_source, arg0, arg1, ret, = CONTRACT_PATTERN.match(node)
          # Conracts puts the first argument types in one list and the list on its own.
          # IE in Contract String, Boolean, Integer => Number, [String, Boolean] end up in one
          # list of nodes and Integer ends up as the first key in a (:pair) node where the values
          # are the return types. I guess this is to allow the => syntax?
          args = arg0 << arg1
          convert_node(node, full_source, args, ret)
        end

        def convert_node(node, full_source, args, ret)
          new_source = ::Sorbet::SorbetFromContractService.source(node, args, ret)
          return nil if new_source.nil?

          lambda do |corrector|
            corrector.replace(
              full_source.source_range,
              new_source,
            )
            add_extend_tsig(corrector, node)
          end
        end

        # Add `extend T::Sig` if not present
        def add_extend_tsig(corrector, node)
          return if node.parent.children.detect { |sib| EXTEND_T_SIG_PATTERN.match(sib) }
          white_space = leading_white_space(node)
          extend_t_source = "extend T::Sig#{white_space}"
          corrector.replace(
            node.parent.children.first.source_range.begin,
            extend_t_source,
          )
        end

        def previous_line(parent)
          if parent.sibling_index > 1
            previous = parent.parent.children[parent.sibling_index - 1]
            if previous&.source_range
              return previous
            end
          end
          parent.parent.children.first
        end

        # Need to replicate the white space leading up to the node
        def leading_white_space(node)
          parent = node.parent
          next_line = parent.children.first
          previous = previous_line(parent)
          end_previous = previous.source_range.end_pos
          begin_next = next_line.source_range.begin_pos
          Parser::Source::Range.new(
            node.parent.source_range.source_buffer,
            end_previous,
            begin_next,
          ).source.gsub(/[0-9a-z\<\_\-]/i, "")
        end
      end
    end
  end
end