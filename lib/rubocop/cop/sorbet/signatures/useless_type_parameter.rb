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

        # @!method type_parameter_usage?(node)
        def_node_matcher(:type_parameter_usage?, <<~PATTERN)
          (call (const {nil? cbase} :T) :type_parameter (sym $_))
        PATTERN

        def on_signature(node)
          usages = Hash.new { |hash, name| hash[name] = [] }
          collect_sorbet_type_parameter_usages(node, usages)

          signature_type_parameter_declarations(node.body).each do |declaration|
            useless = declaration.arguments.select do |argument|
              argument.sym_type? && usages[argument.value].length < 2
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

        def collect_sorbet_type_parameter_usages(node, usages)
          return unless node

          if node.call_type? && (name = type_parameter_usage?(node))
            usages[name] << node
          end
          node.each_descendant(:call) do |call|
            name = type_parameter_usage?(call)
            usages[name] << call if name
          end
        end

        def register_sorbet_offenses(declaration, useless, usages)
          useless.each_with_index do |parameter, index|
            add_offense(parameter, message: format(MSG, name: parameter.value)) do |corrector|
              next if index.nonzero?

              usages.slice(*useless.map(&:value)).each_value do |calls|
                corrector.replace(calls.first, "T.untyped") if calls.one?
              end
              autocorrect_sorbet_declaration(corrector, declaration, useless)
            end
          end
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
            range = range_between(declaration.source_range.begin_pos, declaration.parent.loc.selector.begin_pos)
            corrector.remove(range)
          else
            corrector.remove(declaration)
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
              (occurrences.one? && occurrences.first.first == :signature && !rbs_type_parameter_constrained?(parameter))
          end
          return if useless.empty?

          useless.each_with_index do |parameter, index|
            name_range = parser_range(parameter.location[:name])
            add_offense(name_range, message: format(MSG, name: parameter.name)) do |corrector|
              next if index.nonzero?

              useless.each do |useless_parameter|
                occurrence = usages[useless_parameter.name].first
                corrector.replace(parser_range(occurrence.last.location), "untyped") if occurrence
              end
              autocorrect_rbs_declaration(corrector, method_type, useless)
            end
          end
        end

        def rbs_type_parameter_usages(method_type)
          usages = Hash.new { |hash, name| hash[name] = [] }
          collect_rbs_type_variables(method_type.type, usages, :signature)
          collect_rbs_type_variables(method_type.block.type, usages, :signature) if method_type.block
          method_type.type_params.each do |parameter|
            collect_rbs_type_variables(parameter.upper_bound_type, usages, :bound)
            collect_rbs_type_variables(parameter.lower_bound_type, usages, :bound)
            collect_rbs_type_variables(parameter.default_type, usages, :bound)
          end
          usages
        end

        def collect_rbs_type_variables(type, usages, context)
          return unless type

          usages[type.name] << [context, type] if type.is_a?(RBS::Types::Variable)
          type.each_type { |child| collect_rbs_type_variables(child, usages, context) }
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
