# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks for uses of Sorbet RBS annotations (e.g., `@abstract`, `@interface`, `@sealed`)
      # with dynamic module/class creation using `Module.new` or `Class.new`.
      # These annotations don't work with dynamic instantiation because the RBS rewriter runs
      # before the instantiation rewriter. Instead, regular module/class syntax should be used.
      #
      # @example
      #   # bad
      #   # @abstract
      #   Foo = Class.new
      #
      #   # bad
      #   # @interface
      #   Bar = Module.new(Supermodule)
      #
      #   # bad
      #   # @sealed
      #   Baz = Class.new do
      #     def method
      #     end
      #   end
      #
      #   # good
      #   # @abstract
      #   class Foo
      #   end
      #
      #   # good
      #   # @interface
      #   module Bar
      #     include Supermodule
      #   end
      #
      #   # good
      #   # @sealed
      #   class Baz
      #     def method
      #     end
      #   end
      class RBSAnnotatedModuleNew < Base
        include RangeHelp
        extend AutoCorrector

        MSG = "Sorbet RBS annotations (%<annotation>s) do not work with dynamic `%<module_type>s.new` instantiation. Use regular %<module_type>s syntax instead."

        # @!method module_instantiation_assignment?(node)
        def_node_matcher :module_instantiation_assignment?, <<~PATTERN
          (casgn _ $_ {
            $#module_instantiation? |
            $(block #module_instantiation? ...)
          })
        PATTERN

        # @!method module_instantiation?(node)
        def_node_matcher :module_instantiation?, <<~PATTERN
          (send (const {nil? | cbase} {:Class | :Module}) :new ...)
        PATTERN

        def initialize(config = nil, options = nil)
          super
          annotations = cop_config.fetch("Annotations", [])
          return if annotations.empty?

          # Pre-compile a single regex to match any of the configured annotations
          annotation_pattern = annotations.map { |a| Regexp.escape(a) }.join("|")
          @annotation_regex = /^\s*#\s*@(#{annotation_pattern})(\s|:|$)/
        end

        def on_casgn(node)
          return unless @annotation_regex

          module_instantiation_assignment?(node) do |const_name, instantiation_node|
            # instantiation_node is either a send node or a block node
            send_node = instantiation_node.block_type? ? instantiation_node.send_node : instantiation_node
            module_type = send_node.receiver.const_name.downcase

            # Find the immediately preceding comment that matches our annotation pattern
            annotation_comment = processed_source.ast_with_comments[node]&.find do |comment|
              comment.location.line == node.location.line - 1 &&
                comment.text.match(@annotation_regex)
            end

            return unless annotation_comment

            # Extract which annotation was matched for the message (already captured in last match)
            annotation = Regexp.last_match(1)

            # Get the full constant path
            full_const_name = constant_full_name(node)

            message = format(MSG, annotation: "@#{annotation}", module_type: module_type)
            add_offense(node, message: message) do |corrector|
              autocorrect(corrector, node, full_const_name, instantiation_node, module_type, annotation_comment)
            end
          end
        end

        private

        def constant_full_name(node)
          # For a casgn node, build the full constant path
          # node is (casgn namespace const_name value)
          namespace, const_name, = *node
          
          if namespace
            "#{namespace.const_name}::#{const_name}"
          else
            const_name.to_s
          end
        end

        def autocorrect(corrector, node, const_name, instantiation_node, module_type, annotation_comment) # rubocop:disable Metrics/ParameterLists
          send_node = instantiation_node.block_type? ? instantiation_node.send_node : instantiation_node
          superclass = send_node.first_argument if module_type == "class"

          indent = " " * node.location.column

          # Build the new definition
          parts = [annotation_comment.text]

          parts << if superclass
            "#{indent}class #{const_name} < #{superclass.source}"
          else
            "#{indent}#{module_type} #{const_name}"
          end

          if instantiation_node.block_type? && instantiation_node.body
            parts << indented_body(instantiation_node.body, indent)
          end

          parts << "#{indent}end"

          corrector.replace(
            range_between(annotation_comment.source_range.begin_pos, node.source_range.end_pos),
            parts.compact.join("\n"),
          )
        end

        def indented_body(body_node, base_indent)
          # Get the body source directly from the processed source lines
          body_range = body_node.source_range
          body_lines = processed_source.lines[body_range.line - 1...body_range.last_line]

          # Find minimum indentation of non-empty lines
          min_indent = body_lines.reject { |line| line.strip.empty? }
            .map { |line| line[/^(\s*)/, 1].length }
            .min || 0

          # Re-indent with proper nesting
          body_lines.map do |line|
            content = line.chomp
            if content.strip.empty?
              ""
            else
              # Remove original indent, add new indent
              "#{base_indent}  #{content[min_indent..]}"
            end
          end.join("\n").rstrip
        end
      end
    end
  end
end
