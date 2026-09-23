# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks for type parameters that do not establish a relationship between
      # at least two uses in a Sorbet `sig` or RBS inline signature.
      # Unreferenced parameters and unbounded parameters referenced only once
      # are useless.
      #
      # @example
      #
      #   # bad
      #   sig { type_parameters(:U).params(value: T.type_parameter(:U)).void }
      #
      #   # good
      #   sig { type_parameters(:U).params(value: T.type_parameter(:U)).returns(T.type_parameter(:U)) }
      #
      #   # bad
      #   #: [U] () -> U
      #   def foo; end
      #
      #   # good
      #   #: [U] (U) -> U
      #   def foo(value); end
      class UselessTypeParameter < ::RuboCop::Cop::Base
        extend AutoCorrector
        include RangeHelp
        include SignatureHelp

        MSG = "Type parameter `%<name>s` must be referenced at least twice."

        # @!method type_parameter_argument(node)
        def_node_matcher(:type_parameter_argument, <<~PATTERN)
          (call (const {nil? cbase} :T) :type_parameter $_)
        PATTERN

        # @!method type_combination?(node)
        def_node_matcher(:type_combination?, <<~PATTERN)
          (call (const {nil? cbase} :T) {:all :any} ...)
        PATTERN

        def on_signature(node)
          usages = Hash.new { |hash, name| hash[name] = [] }
          collect_sorbet_type_parameter_usages(node, usages)

          signature_type_parameter_declarations(node.body).each do |declaration|
            useless = declaration.arguments.select do |argument|
              occurrences = usages[argument.value]
              argument.sym_type? && (occurrences.empty? || (occurrences.one? && occurrences.first[1]))
            end
            register_sorbet_offenses(declaration, useless, usages) if useless.any?
          end
        end

        def on_def(node)
          check_rbs_signatures(node)
        end
        alias_method :on_defs, :on_def

        private

        def signature_type_parameter_declarations(node)
          declarations = []
          while node&.call_type?
            declarations << node if node.method?(:type_parameters)
            node = node.receiver
          end
          declarations
        end

        def type_parameter_usage(node)
          argument = type_parameter_argument(node)
          argument = unwrap_parentheses(argument)
          argument.value if argument&.sym_type?
        end

        def unwrap_parentheses(node)
          node = node.children.first while node&.begin_type? && node.children.one?
          node
        end

        def collect_sorbet_type_parameter_usages(node, usages)
          return unless node

          if node.call_type? && (name = type_parameter_usage(node))
            usages[name] << [node, sorbet_usage_replacement_target(node)]
          end
          node.each_descendant(:call) do |call|
            name = type_parameter_usage(call)
            usages[name] << [call, sorbet_usage_replacement_target(call)] if name
          end
        end

        def register_sorbet_offenses(declaration, useless, usages)
          useless.each_with_index do |parameter, index|
            add_offense(parameter, message: format(MSG, name: parameter.value)) do |corrector|
              next if index.nonzero?

              sorbet_usage_corrections(useless, usages).each_value do |target, replacement|
                corrector.replace(target, replacement)
              end
              autocorrect_sorbet_declaration(corrector, declaration, useless)
            end
          end
        end

        def sorbet_usage_replacement_target(call)
          expression = call
          expression = expression.parent while expression.parent&.begin_type? && expression.parent.children.one?
          parent = expression.parent
          return parent if type_combination?(parent) && parent.arguments.include?(expression)

          call if standalone_sorbet_type?(expression, parent)
        end

        def standalone_sorbet_type?(expression, parent)
          return parent.children[1].equal?(expression) if parent&.pair_type?

          parent&.call_type? && parent.method?(:returns) && parent.first_argument.equal?(expression)
        end

        def sorbet_usage_corrections(useless, usages)
          useless_names = useless.map(&:value).to_set
          useless.each_with_object({}) do |parameter, corrections|
            target = usages[parameter.value].first&.at(1)
            next unless target

            replacement = if type_combination?(target)
              remaining = target.arguments.reject do |argument|
                useless_names.include?(type_parameter_usage(unwrap_parentheses(argument)))
              end
              sorbet_combination_replacement(target, remaining)
            else
              "T.untyped"
            end
            corrections[target.source_range.begin_pos] = [target, replacement]
          end
        end

        def sorbet_combination_replacement(combination, remaining)
          return "T.untyped" if combination.method?(:any)
          return "T.untyped" if remaining.empty?
          return remaining.first.source if remaining.one?

          "#{combination.receiver.source}.#{combination.method_name}(#{remaining.map(&:source).join(", ")})"
        end

        def autocorrect_sorbet_declaration(corrector, declaration, useless)
          remaining = declaration.arguments - useless
          if remaining.any?
            arguments = range_between(
              declaration.first_argument.source_range.begin_pos,
              declaration.last_argument.source_range.end_pos,
            )
            corrector.replace(arguments, remaining.map(&:source).join(", "))
          elsif declaration.receiver
            corrector.replace(declaration, declaration.receiver.source)
          elsif declaration.parent&.call_type? && declaration.parent.receiver.equal?(declaration)
            promoted_call = declaration.parent
            reindent_promoted_call(corrector, declaration, promoted_call)
            range = range_between(declaration.source_range.begin_pos, promoted_call.loc.selector.begin_pos)
            corrector.remove(range)
          else
            corrector.remove(declaration)
          end
        end

        def reindent_promoted_call(corrector, declaration, promoted_call)
          dot = promoted_call.loc.dot
          continuation_column = dot.line == promoted_call.loc.selector.line ? dot.column : promoted_call.loc.selector.column
          indentation_width = continuation_column - declaration.source_range.column
          return unless indentation_width.positive?

          first_line = promoted_call.loc.selector.line + 1
          (first_line..promoted_call.source_range.last_line).each do |line|
            line_range = processed_source.buffer.line_range(line)
            indentation = line_range.source[/\A[ \t]*/]
            next if indentation.length < indentation_width

            corrector.remove(range_between(line_range.begin_pos, line_range.begin_pos + indentation_width))
          end
        end

        def check_rbs_signatures(node)
          ::RuboCop::Sorbet::RBSParser.rbs_signatures_before(processed_source, node).each do |signature|
            check_rbs_signature(signature.method_type)
          end
        end

        def check_rbs_signature(method_type)
          return unless method_type

          usages = rbs_type_parameter_usages(method_type)
          useless = method_type.type_params.select do |parameter|
            occurrences = usages[parameter.name]
            occurrences.empty? ||
              (occurrences.one? && occurrences.first[2] && !rbs_type_parameter_constrained?(parameter))
          end
          return if useless.empty?

          useless.each_with_index do |parameter, index|
            name_range = parser_range(parameter.location[:name])
            add_offense(name_range, message: format(MSG, name: parameter.name)) do |corrector|
              next if index.nonzero?

              rbs_usage_corrections(useless, usages).each_value do |location, replacement|
                corrector.replace(parser_range(location), replacement)
              end
              autocorrect_rbs_declaration(corrector, method_type, useless)
            end
          end
        end

        def rbs_type_parameter_usages(method_type)
          usages = Hash.new { |hash, name| hash[name] = [] }
          method_type.type.each_type { |type| collect_rbs_type_variables(type, usages, :signature, direct: true) }
          method_type.block&.type&.each_type do |type|
            collect_rbs_type_variables(type, usages, :signature, direct: true)
          end
          method_type.type_params.each do |parameter|
            collect_rbs_type_variables(parameter.upper_bound_type, usages, :bound, direct: false)
            collect_rbs_type_variables(parameter.lower_bound_type, usages, :bound, direct: false)
            collect_rbs_type_variables(parameter.default_type, usages, :bound, direct: false)
          end
          usages
        end

        def collect_rbs_type_variables(type, usages, context, direct:)
          return unless type

          if type.is_a?(RBS::Types::Variable)
            replacement = direct ? [type.location, "untyped"] : [nil, nil]
            usages[type.name] << [context, type, *replacement, nil]
          elsif type.is_a?(RBS::Types::Intersection)
            collect_rbs_intersection_variables(type, usages, context)
          elsif type.is_a?(RBS::Types::Union)
            collect_rbs_union_variables(type, usages, context)
          else
            type.each_type { |child| collect_rbs_type_variables(child, usages, context, direct: false) }
          end
        end

        def collect_rbs_intersection_variables(intersection, usages, context)
          intersection.types.each do |type|
            if type.is_a?(RBS::Types::Variable)
              remaining = intersection.types.reject { |candidate| candidate.equal?(type) }
              usages[type.name] << [
                context,
                type,
                intersection.location,
                remaining.map(&:to_s).join(" & "),
                intersection,
              ]
            else
              collect_rbs_type_variables(type, usages, context, direct: false)
            end
          end
        end

        def collect_rbs_union_variables(union, usages, context)
          union.types.each do |type|
            if type.is_a?(RBS::Types::Variable)
              usages[type.name] << [context, type, union.location, "untyped", nil]
            else
              collect_rbs_type_variables(type, usages, context, direct: false)
            end
          end
        end

        def rbs_usage_corrections(useless, usages)
          useless_names = useless.map(&:name).to_set
          useless.each_with_object({}) do |parameter, corrections|
            occurrence = usages[parameter.name].first
            next unless occurrence

            location = occurrence[2]
            intersection = occurrence[4]
            replacement = if intersection
              remaining = intersection.types
                .reject { |type| type.is_a?(RBS::Types::Variable) && useless_names.include?(type.name) }
                .map(&:to_s)
              remaining.empty? ? "untyped" : remaining.join(" & ")
            else
              occurrence[3]
            end
            corrections[[location.start_pos, location.end_pos]] = [location, replacement]
          end
        end

        def rbs_type_parameter_constrained?(parameter)
          parameter.upper_bound_type || parameter.lower_bound_type || parameter.default_type
        end

        def autocorrect_rbs_declaration(corrector, method_type, useless)
          remaining = method_type.type_params - useless
          type_params_location = method_type.location[:type_params]

          if remaining.any?
            corrector.replace(parser_range(type_params_location), "[#{remaining.map(&:to_s).join(", ")}]")
          else
            type_location = method_type.location[:type]
            range = range_between(type_params_location.start_pos, type_location.start_pos)
            corrector.remove(range)
          end
        end

        def parser_range(location)
          Parser::Source::Range.new(processed_source.buffer, location.start_pos, location.end_pos)
        end
      end
    end
  end
end
