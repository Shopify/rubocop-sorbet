# frozen_string_literal: true

#
# In preparation for adding Sorbet to the codebase we must remove all dynamic imports as these
# make type checking impossible. The biggest single offender in our codebase is `Dry::Types.module`
# which includes all the types like Strict::String, Coercible::Int, Types::Bool, etc.
#
# Instead of using these auto-magic includes, we must use ths static path. In most cases this is
# can be done automatically by this class, so:
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
      class NoDynamicContractIncludes < Cop
        MSG = "Sorbet disallows dynamic includes. Do not include Dry::Types.module directly; use direct path instead."
        MSG_PATH = "Sorbet disallows dynamic includes. Use full Dry::Types path instead."

        def_node_matcher :include_statement, <<-PATTERN
          (send _ :include (send (const (const _ :Dry) :Types) _))
        PATTERN

        def_node_matcher :instance_statement, <<-PATTERN
          (send _ :Instance (const ...))
        PATTERN

        def_node_matcher :const_statement, <<-PATTERN
          (const (const _ {:Strict :Coercible}) _)
        PATTERN

        def_node_matcher :types_statement, <<-PATTERN
          (const (const _ :Types) {:DateTime :String :Bool :Array :Int :Hash :Date})
        PATTERN

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

        DYNAMIC_REFERENCE_PATTERN = NodePattern.new("$(const (const _ ${:Strict :Coercible}) $_)")
        INSTANCE_PATTERN = NodePattern.new("$(send _ :Instance (const _ $_))")
        TYPES_PATTERN = NodePattern.new("$(const (const _ :Types) ${:DateTime :String :Bool :Array :Int :Hash :Date})")

        def autocorrect(node)
          if DYNAMIC_REFERENCE_PATTERN.match(node)
            correct_dynamic_class_reference(node)
          elsif INSTANCE_PATTERN.match(node)
            correct_instance_class_reference(node)
          elsif TYPES_PATTERN.match(node)
            correct_types_reference(node)
          end
        end

        def klass_to_str(klass)
          klass_str = klass.to_s.downcase
          if klass_str == "datetime"
            "date_time"
          else
            klass_str
          end
        end

        def correct_types_reference(node)
          full_source, klass = TYPES_PATTERN.match(node)
          klass_str = klass_to_str(klass)
          new_source = format("Dry::Types[\"%s\"]", klass_str)
          lambda do |corrector|
            corrector.replace(
              full_source.source_range,
              new_source,
            )
          end
        end

        def correct_instance_class_reference(node)
          full_source, klass = INSTANCE_PATTERN.match(node)
          klass_str = klass.to_s
          new_source = format("Dry::Types::Definition.new(%s).constrained(type: %s)", klass_str, klass_str)
          lambda do |corrector|
            corrector.replace(
              full_source.source_range,
              new_source,
            )
          end
        end

        def correct_dynamic_class_reference(node)
          full_source, strictness, primitive = DYNAMIC_REFERENCE_PATTERN.match(node)
          strictness_str = strictness.to_s.downcase
          primitive_str = klass_to_str(primitive)
          new_source = format("Dry::Types[\"%s.%s\"]", strictness_str, primitive_str)
          lambda do |corrector|
            corrector.replace(
              full_source.source_range,
              new_source,
            )
          end
        end
      end
    end
  end
end
