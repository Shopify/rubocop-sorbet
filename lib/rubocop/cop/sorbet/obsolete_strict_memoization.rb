# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Checks for the obsolete pattern for initializing instance variables that was required for older Sorbet
      # versions in `#typed: strict` files.
      #
      # It's no longer required, as of Sorbet 0.5.10210
      # See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization
      #
      # @example
      #
      #   # bad
      #   sig { returns(Foo) }
      #   def foo
      #     @foo = T.let(@foo, T.nilable(Foo))
      #     @foo ||= Foo.new
      #   end
      #
      #   # good
      #   sig { returns(Foo) }
      #   def foo
      #     @foo ||= T.let(Foo.new, T.nilable(Foo))
      #   end
      #
      class ObsoleteStrictMemoization < RuboCop::Cop::Base
        include RuboCop::Cop::MatchRange
        include RuboCop::Cop::Alignment
        extend AutoCorrector

        include TargetSorbetVersion
        minimum_target_sorbet_static_version "0.5.10210"

        MESSAGE = "This two-stage workaround for memoization in `#typed: strict` files is no longer necessary. " \
          "See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization."

        # @!method legacy_memoization_pattern?(node)
        def_node_matcher :legacy_memoization_pattern?, <<~PATTERN
          (begin
            ...                                           # Match and ignore any other lines that come first.
            $(ivasgn $_ivar                               # First line: @_ivar = ...
              (send                                       # T.let(_ivar, T.nilable(_ivar_type))
                (const nil? :T) :let
                (ivar _ivar)
                (send                                     # T.nilable(_ivar_type)
                  (const nil? :T) :nilable $_ivar_type)))
            ...
            $(or-asgn                                     # Second line: @_ivar ||= _initialization_expr
              (ivasgn _ivar)
              $_initialization_expr))
        PATTERN

        def on_begin(node)
          expression = legacy_memoization_pattern?(node)
          return unless expression

          first_assignment_node, ivar, ivar_type, second_conditional_assignment_node, initialization_expr = expression

          add_offense(first_assignment_node, message: MESSAGE) do |corrector|
            base_indent = offset(node)

            is_multiline_init_expr = initialization_expr.line_count != 1

            correction = if is_multiline_init_expr
              render_multi_line_correction(ivar, ivar_type, initialization_expr, base_indent)
            else
              single_line_correction =
                "#{ivar} ||= T.let(#{initialization_expr.source}, T.nilable(#{ivar_type.source}))"

              if (base_indent.length + single_line_correction.length) <= max_line_length
                single_line_correction
              else # The single-line correction was too long. Re-render it as a multi-line correction.
                render_multi_line_correction(ivar, ivar_type, initialization_expr, base_indent)
              end
            end

            corrector.replace(first_assignment_node, correction)
            remove_whitespace_lines_between(first_assignment_node, second_conditional_assignment_node, corrector)
            corrector.remove(range_by_whole_lines(second_conditional_assignment_node.source_range,
              include_final_newline: true))
          end
        end

        def relevant_file?(file)
          super && enabled_for_sorbet_static_version?
        end

        private

        def single_indent
          @single_indent ||= case config.for_cop("Layout/IndentationStyle")["EnforcedStyle"]
          when "tabs" then "\t"
          when "spaces", nil then " " * configured_indentation_width
          end
        end

        def render_multi_line_correction(ivar, ivar_type, initialization_expr, base_indent)
          indent = single_indent
          initialization_expr_source = initialization_expr.source.lines.map { |line| indent + line }.join

          <<~RUBY.chomp
            #{ivar} ||= T.let(
            #{base_indent}#{initialization_expr_source},
            #{base_indent}#{indent}T.nilable(#{ivar_type.source}),
            #{base_indent})
          RUBY
        end

        def remove_whitespace_lines_between(start_node, end_node, corrector)
          begin_pos = processed_source.buffer.line_range(start_node.last_line + 1).end_pos
          end_pos = end_node.source_range.begin_pos

          return unless begin_pos < end_pos

          corrector.remove(range_between(begin_pos, end_pos))
        end
      end
    end
  end
end
