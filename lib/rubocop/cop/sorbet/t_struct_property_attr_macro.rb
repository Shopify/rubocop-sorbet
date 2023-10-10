# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks for the use of `attr_*` methods matching a `const` or `prop` in a `T::Struct`.
      #
      # @example
      #   # bad – pointless `attr_*` method
      #   class Foo < T::Struct
      #     attr_reader :bar
      #     attr_reader :biz
      #     attr_writer :biz
      #     attr_accessor :baz
      #
      #     const :bar, String
      #     prop :biz, String
      #     prop :baz, String
      #   end
      #
      #   # good
      #   class Foo < T::Struct
      #     const :bar, String
      #     prop :biz, String
      #     prop :baz, String
      #   end
      #
      # @example
      #   # bad – defining writer method for `const` property
      #   class Foo < T::Struct
      #     attr_writer :bar
      #     attr_accessor :biz
      #
      #     const :bar, String
      #     const :biz, String
      #   end
      #
      #   # good – mutable property defined with `prop`
      #   class Foo < T::Struct
      #     prop :bar, String
      #     prop :biz, String
      #   end
      #
      # @example
      #   # good – customized attribute access – although this is not a recommended pattern with T::Struct
      #   class Foo < T::Struct
      #     const :bar, String
      #     prop :biz, String
      #
      #     def bar
      #       # ...
      #     end
      #
      #     def biz=(value)
      #       # ...
      #     end
      #   end
      class TStructPropertyAttrMacro < Base
        MUTABILITY_MSG = "Use `T::Struct.prop` instead of `%{keyword}` to define `%{name}` property as mutable."
        OVERRIDE_MSG = "Do not override `T::Struct` `%{name}` property %{attr_method_type} unless customizing it."

        class Macro
          def initialize(node)
            @node = node
          end

          def name
            @name_node.value
          end

          def name_source_range
            @name_node.source_range
          end

          def keyword
            @node.method_name.to_sym
          end

          def inspect
            "#{keyword} #{name.inspect}"
          end
        end

        class StructMacro < Macro
          class << self
            def for(node)
              new(node)
            end
          end

          def initialize(node)
            super
            @name_node = node.first_argument
          end
        end

        class AttrMacro < Macro
          class << self
            def for(node)
              # `attr_*` macros can define multiple properties at once, so we return an array instead of a single macro.
              node.arguments.map.with_index do |_, index|
                new(node, index: index)
              end
            end
          end

          def initialize(node, index:)
            super(node)
            @name_node = node.arguments.fetch(index)
          end

          def attr_method_type
            keyword.to_s.delete_prefix("attr_")
          end
        end

        MACRO_CLASSES = {
          attr_reader: AttrMacro,
          attr_writer: AttrMacro,
          attr_accessor: AttrMacro,
          const: StructMacro,
          prop: StructMacro,
        }.freeze

        # @!method t_struct?(node)
        def_node_matcher :t_struct?, <<~PATTERN
          (class _ (const (const {nil? cbase} :T) {:Struct :ImmutableStruct :InexactStruct} ) (begin $...))
        PATTERN

        # @!method relevant_macro?(node)
        def_node_matcher :relevant_macro?, <<~PATTERN
          (send nil? {#{MACRO_CLASSES.keys.map(&:inspect).join(" ")}} ...)
        PATTERN

        def on_class(node)
          each_relevant_macro_group(node) do |name, readers:, writers:, consts:, props:|
            writers.each do |macro|
              add_offense(
                macro.name_source_range,
                message: format(MUTABILITY_MSG, keyword: macro.keyword, name: name.inspect),
              )
            end unless consts.empty?

            readers.each do |macro|
              add_offense(
                macro.name_source_range,
                message: format(OVERRIDE_MSG, name: name.inspect, attr_method_type: macro.attr_method_type),
              )
            end unless consts.empty? && props.empty?

            writers.each do |macro|
              add_offense(
                macro.name_source_range,
                message: format(OVERRIDE_MSG, name: name.inspect, attr_method_type: macro.attr_method_type),
              )
            end unless props.empty?
          end
        end

        private

        def each_relevant_macro_group(node)
          t_struct?(node) do |expressions|
            expressions
              .select { |expression| relevant_macro?(expression) }
              .flat_map { |expression| MACRO_CLASSES.fetch(expression.method_name).for(expression) }
              .group_by(&:name)
              .each do |name, macros|
                next if macros.length == 1

                readers = macros.select { _1.keyword == :attr_reader || _1.keyword == :attr_accessor }
                writers = macros.select { _1.keyword == :attr_writer || _1.keyword == :attr_accessor }
                consts  = macros.select { _1.keyword == :const }
                props   = macros.select { _1.keyword == :prop }

                yield name, readers: readers, writers: writers, consts: consts, props: props
              end
          end
        end
      end
    end
  end
end
