# frozen_string_literal: true

# Disallows use of DryTypes dynamic include and converts DryTypes classes to full static paths.
#
# Sorbet does not allow the dynamic includes statements permitted by Ruby because of the
# impossibility of statically typing this construct. The DryTypes gem makes frequent use
# of dynamic includes with `Dry::Types.module` which includes all the primitive types
# such as Strict::String, Coercible::Int, Types::Bool, etc.
#
# To add Sorbet to a codebase, instead of using this dynamic includes to mass include all the types
# we must use the full static paths of the types we need.
# In most cases this is can be done automatically by this class, so:
#
# Strict::String -> Dry::Types['strict.string']
# Coercible::Int -> Dry::Types['coercible.string']
# Types::Bool -> Dry::Types['bool']
# Strict::Array.of(Strict::String) -> Dry::Types["strict.array"].of
# Strict::DateTime -> Dry::Types["strict.date_time"]
# Instance(Carrier) -> Dry::Types::Definition.new(Carrier).constrained(type: Carrier)
#
# Some were not automate-able and must be done manually. These are:
#
# Any -> Dry::Types::Any
# Hash -> Dry::Types["hash"]
# Nil -> Dry::Types["nil"]
#
module RuboCop
  module Cop
    module Sorbet
      class NoDynamicDryTypesIncludes < Cop
        MSG = "Sorbet disallows dynamic includes. Do not include Dry::Types.module directly; use direct path instead."
        MSG_PATH = "Sorbet disallows dynamic includes. Use full Dry::Types path instead."

        DYNAMIC_REFERENCE_PATTERN = NodePattern.new("$(const (const _ ${:Strict :Coercible}) $_)")
        TYPES_PATTERN = NodePattern.new("$(const (const _ :Types) ${:DateTime :String :Bool :Array :Int :Hash :Date})")
        INSTANCE_PATTERN = NodePattern.new("$(send _ :Instance (const _ $_))")

        def_node_matcher :include_statement, <<-PATTERN
          (send _ :include (send (const (const _ :Dry) :Types) _))
        PATTERN

        def_node_matcher :instance_statement, INSTANCE_PATTERN.pattern

        def_node_matcher :const_statement, DYNAMIC_REFERENCE_PATTERN.pattern

        def_node_matcher :types_statement, TYPES_PATTERN.pattern

        def on_const(node)
          types_statement(node) do |_statement|
            add_offense(node, message: MSG_PATH)
          end
          const_statement(node) do |_statement|
            add_offense(node, message: MSG_PATH)
          end
        end

        def on_send(node)
          instance_statement(node) do |_statement|
            add_offense(node, message: MSG)
          end
          include_statement(node) do |_statement|
            add_offense(node, message: MSG)
          end
        end

        def autocorrect(node)
          if DYNAMIC_REFERENCE_PATTERN.match(node)
            correct_dynamic_class_reference(node)
          elsif INSTANCE_PATTERN.match(node)
            correct_instance_class_reference(node)
          elsif TYPES_PATTERN.match(node)
            correct_types_reference(node)
          end
        end

        def corrector(full_source, new_source)
          lambda do |corrector|
            corrector.replace(
              full_source.source_range,
              new_source,
            )
          end
        end

        def klass_to_str(klass)
          klass_str = klass.to_s.downcase
          return "date_time" if klass_str == "datetime"
          klass_str
        end

        def correct_types_reference(node)
          full_source, klass = TYPES_PATTERN.match(node)
          klass_str = klass_to_str(klass)
          new_source = format("Dry::Types[\"%s\"]", klass_str)
          corrector(full_source, new_source)
        end

        def correct_instance_class_reference(node)
          full_source, klass = INSTANCE_PATTERN.match(node)
          klass_str = klass.to_s
          new_source = format("Dry::Types::Definition.new(%s).constrained(type: %s)", klass_str, klass_str)
          corrector(full_source, new_source)
        end

        def correct_dynamic_class_reference(node)
          full_source, strictness, primitive = DYNAMIC_REFERENCE_PATTERN.match(node)
          strictness_str = strictness.to_s.downcase
          primitive_str = klass_to_str(primitive)
          new_source = format("Dry::Types[\"%s.%s\"]", strictness_str, primitive_str)
          corrector(full_source, new_source)
        end
      end
    end
  end
end
