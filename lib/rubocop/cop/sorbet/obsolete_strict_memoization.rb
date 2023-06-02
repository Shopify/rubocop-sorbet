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
          expression = legacy_memoization_pattern?(node)
          return unless expression

          add_offense(node, message: MESSAGE) do |corrector|
            ivar, ivar_type, initialization_expr = expression

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

            corrector.replace(node, correction)
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
      end
    end
  end
end
