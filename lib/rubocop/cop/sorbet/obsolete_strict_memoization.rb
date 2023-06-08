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
      # TODO: disable this cop when the Sorbet version is older than `0.5.10210`.
      # TODO: find the right way to access the line length limit, indentation style, and indentation width.
      class ObsoleteStrictMemoization < RuboCop::Cop::Cop
        include RuboCop::Cop::MatchRange

        MESSAGE = "This two-stage workaround for memoization in `#typed: strict` files is no longer necessary. " \
          "See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization."

        # @!method legacy_memoization_pattern?(node)
        def_node_matcher :legacy_memoization_pattern?, <<~PATTERN
          (begin
            (ivasgn $_ivar                                # @_ivar = ...
              (send                                       # T.let(_ivar, T.nilable(_ivar_type))
                (const nil? :T) :let
                (ivar _ivar)
                (send                                     # T.nilable(_ivar_type)
                  (const nil? :T) :nilable $_ivar_type)))
            (or-asgn                                      # @_ivar ||= _initialization_expr
              (ivasgn _ivar)
              $_initialization_expr))
        PATTERN

        def on_begin(node)
          return unless legacy_memoization_pattern?(node)

          add_offense(node, message: MESSAGE)
        end

        def autocorrect(node)
          ->(corrector) {
            expression = legacy_memoization_pattern?(node)
            ivar, ivar_type, initialization_expr = expression

            base_indent = infer_base_indentation(node)

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

            corrector.replace(node, correction)
          }
        end

        private

        def single_indent
          @single_indent ||= begin
            ident_style_config = config.for_cop("Layout/IndentationStyle")

            case ident_style_config["EnforcedStyle"]
            when "tabs"
              "\t"

            when "spaces", nil
              space_width = ident_style_config["IndentationWidth"] ||
                config.for_cop("Layout/IndentationWidth")["Width"] || 2

              " " * space_width
            end
          end
        end

        # Gives the base indentation of source text in the node,
        # i.e. which indentation level is in common for all lines.
        def infer_base_indentation(node)
          # The first line of the node has the indentation already stripped,
          # so we infer the base indent from next non-blank line.
          second_line = node.source.lines.drop(1).find { |line| !line.strip.empty? }
          /^\s*/.match(second_line)[0]
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
      end
    end
  end
end
