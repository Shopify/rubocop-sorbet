# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Shared guards and rewrites for replacing Sorbet runtime assertions
      # with equivalent RBS inline comments.
      module RBSAssertionCorrection
        include RangeHelp
        include Alignment

        COMMENT_START = "#"
        NEWLINES = ["\n", "\r"].freeze

        private

        def autocorrect_rbs_assertion(corrector, node, allow_assignment: false)
          context = rbs_assertion_correction_context(node, allow_assignment: allow_assignment)
          return unless context

          replacement = yield
          case context.first
          when :direct
            corrector.replace(node, replacement)
          when :arguments
            autocorrect_argument_list(corrector, node, replacement, context)
          end
        end

        def rbs_assertion_correction_context(node, allow_assignment:)
          return [:direct] if rbs_assertion_autocorrectable?(node, allow_assignment: allow_assignment)
          return unless nested_rbs_assertion_autocorrectable?(node)

          call_argument_context(node)
        end

        def call_argument_context(node)
          parent = node.parent
          if parent&.type?(:call) && parent.arguments.include?(node)
            call = parent
            target = node
          elsif parent&.splat_type?
            call = parent.parent
            return unless call&.type?(:call) && call.arguments.include?(parent)

            target = parent
          elsif parent&.kwsplat_type?
            argument = node.first_argument
            return if argument.hash_type? && !argument.loc.begin

            hash = parent.parent
            return unless hash&.hash_type? && !hash.loc.begin

            call = hash.parent
            return unless call&.type?(:call) && call.arguments.include?(hash)

            target = parent
          elsif parent&.pair_type? && parent.value.equal?(node)
            hash = parent.parent
            return unless hash&.hash_type? && !hash.loc.begin

            call = hash.parent
            return unless call&.type?(:call) && call.arguments.include?(hash)

            target = parent
          else
            return
          end

          return unless call.single_line? && call.loc.begin && call.loc.end
          return if comments_within?(call)
          return unless one_matching_assertion?(call, node)

          items = call.arguments.flat_map do |argument|
            argument.hash_type? && !argument.loc.begin ? argument.children : argument
          end
          return unless items.include?(target)

          [:arguments, call, items, target]
        end

        def autocorrect_argument_list(corrector, node, replacement, context)
          _, container, items, target = context
          indentation = container.source_range.source_line[/\A[ \t]*/]
          item_indentation = indentation + (" " * configured_indentation_width)
          splat = target.type?(:splat, :kwsplat)
          target_index = items.index(target)
          if splat
            nested_indentation = item_indentation + (" " * configured_indentation_width)
            replacement = "(\n#{nested_indentation}#{replacement}\n#{item_indentation})"
          elsif target_index < items.length - 1
            replacement = replacement.sub(" #:", ", #:")
          end
          corrector.replace(node, replacement)

          corrector.replace(container.loc.begin.end.join(items.first.source_range.begin), "\n#{item_indentation}")
          items.each_cons(2) do |item, next_item|
            separator = item.equal?(target) && !splat ? "" : ","
            corrector.replace(item.source_range.end.join(next_item.source_range.begin), "#{separator}\n#{item_indentation}")
          end
          corrector.replace(items.last.source_range.end.join(container.loc.end.begin), "\n#{indentation}")
        end

        def comments_within?(node)
          range = node.source_range
          processed_source.comments.any? do |comment|
            comment.source_range.begin_pos >= range.begin_pos && comment.source_range.end_pos <= range.end_pos
          end
        end

        def one_matching_assertion?(container, node)
          container.each_node(:send).count do |candidate|
            candidate.method?(node.method_name) &&
              candidate.receiver&.const_type? &&
              candidate.receiver.const_name == "T"
          end == 1
        end

        def nested_rbs_assertion_autocorrectable?(node)
          return false unless cop_config["AutocorrectToRBS"]
          return false unless node.single_line?
          return false if inside_single_line_block?(node)
          return false if ::RuboCop::Sorbet::RBSParser.rbs_annotation_after(processed_source, node)

          true
        end

        def inside_single_line_block?(node)
          node.each_ancestor.any? { |ancestor| ancestor.type?(:block, :numblock) && ancestor.single_line? }
        end

        def rbs_assertion_autocorrectable?(node, allow_assignment: false)
          return false unless cop_config["AutocorrectToRBS"]
          return false unless assertion_ends_line?(node)
          return false if ::RuboCop::Sorbet::RBSParser.rbs_annotation_after(processed_source, node)

          statement = assertion_statement(node, allow_assignment: allow_assignment)
          statement && statement.source_range.source_line.index(/\S/) == statement.source_range.column
        end

        def assertion_statement(node, allow_assignment:)
          parent = node.parent
          return node unless parent&.assignment? && parent.children.last.equal?(node)

          parent if allow_assignment
        end

        def assertion_ends_line?(node)
          range = range_after_horizontal_whitespace(node)
          character = range.source_buffer.source[range.end_pos]

          character.nil? || NEWLINES.include?(character) || character == COMMENT_START
        end

        def range_after_horizontal_whitespace(node)
          range_with_surrounding_space(node.source_range, side: :right, newlines: false)
        end
      end
    end
  end
end
