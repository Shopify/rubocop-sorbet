# frozen_string_literal: true

require "rubocop"
require "rbi"

module RuboCop
  module Cop
    module Sorbet
      # Disallow using `T::Struct` and `T::Props`.
      #
      # @example
      #
      #   # bad
      #   class MyStruct < T::Struct
      #     const :foo, String
      #     prop :bar, Integer, default: 0
      #
      #     def some_method; end
      #   end
      #
      #   # good
      #   class MyStruct
      #     extend T::Sig
      #
      #     sig { returns(String) }
      #     attr_reader :foo
      #
      #     sig { returns(Integer) }
      #     attr_accessor :bar
      #
      #     sig { params(foo: String, bar: Integer) }
      #     def initialize(foo:, bar: 0)
      #       @foo = foo
      #       @bar = bar
      #     end
      #
      #     def some_method; end
      #   end
      #
      # @example AutocorrectStyle: rbs
      #
      #   # bad
      #   class MyStruct < T::Struct
      #     const :foo, String
      #     prop :bar, T.nilable(Integer), default: 0
      #   end
      #
      #   # good
      #   class MyStruct
      #     #: String
      #     attr_reader :foo
      #
      #     #: Integer?
      #     attr_accessor :bar
      #
      #     #: (foo: String, ?bar: Integer?) -> void
      #     def initialize(foo:, bar: 0)
      #       @foo = foo
      #       @bar = bar
      #     end
      #   end
      #
      class ForbidTStruct < RuboCop::Cop::Base
        include Alignment
        include RangeHelp
        include CommentsHelp
        extend AutoCorrector

        RESTRICT_ON_SEND = [:include, :prepend, :extend].freeze

        MSG_STRUCT = "Using `T::Struct` or its variants is deprecated in this codebase."
        MSG_PROPS = "Using `T::Props` or its variants is deprecated in this codebase."

        VALID_AUTOCORRECT_STYLES = ["sig", "rbs"].freeze
        # This class walks down the class body of a T::Struct and collects all the properties that will need to be
        # translated into `attr_reader` and `attr_accessor` methods.
        class TStructWalker
          include AST::Traversal
          extend AST::NodePattern::Macros
          attr_reader :props, :has_extend_t_sig, :extend_t_sig_node

          def initialize(style = "sig")
            @props = []
            @has_extend_t_sig = false
            @extend_t_sig_node = nil
            @style = style
          end

          # @!method extend_t_sig?(node)
          def_node_matcher :extend_t_sig?, <<~PATTERN
            (send _ :extend (const (const {nil? | cbase} :T) :Sig))
          PATTERN

          # @!method t_struct_prop?(node)
          def_node_matcher(:t_struct_prop?, <<~PATTERN)
            (send nil? {:const :prop} ...)
          PATTERN

          def on_send(node)
            if extend_t_sig?(node)
              # So we know we won't need to generate again a `extend T::Sig` line in the new class body
              @has_extend_t_sig = true
              @extend_t_sig_node = node
              return
            end

            return unless t_struct_prop?(node)

            kind = node.method?(:const) ? :attr_reader : :attr_accessor
            name = node.first_argument.source.delete_prefix(":")
            type = node.arguments[1].source
            default = nil
            factory = nil

            node.arguments[2..-1].each do |arg|
              next unless arg.hash_type?

              arg.each_pair do |key, value|
                case key.source
                when "default"
                  default = value.source
                when "factory"
                  factory = value.source
                end
              end
            end

            @props << Property.new(node, kind, name, type, default: default, factory: factory, style: @style)
          end
        end

        class Property
          attr_reader :node, :kind, :name, :default, :factory

          def initialize(node, kind, name, type, default:, factory:, style: "sig")
            @node = node
            @kind = kind
            @name = name
            @type = type
            @default = default
            @factory = factory
            @style = style

            # A T::Struct should have both a default and a factory, if we find one let's raise an error
            raise if @default && @factory
          end

          def attr_sig
            if rbs?
              "#: #{rbs_type}"
            else
              "sig { returns(#{type}) }"
            end
          end

          def attr_accessor
            "#{kind} :#{name}"
          end

          def initialize_sig_param
            type_str = rbs? ? rbs_type : type
            return "?#{name}: #{type_str}" if rbs? && optional?

            "#{name}: #{type_str}"
          end

          def initialize_param
            rb = String.new
            rb << "#{name}:"
            if default
              rb << " #{default}"
            elsif factory
              rb << " #{factory}"
            elsif nilable?
              rb << " nil"
            end
            rb
          end

          def initialize_assign
            rb = String.new
            rb << "@#{name} = #{name}"
            rb << ".call" if factory
            rb
          end

          def nilable?
            type.start_with?("T.nilable(")
          end

          # A prop is optional when it declares a `default:`, a `factory:`, or
          # is nilable (which gives it an implicit `nil` default). RBS marks
          # optional keyword parameters with `?name:`, mirroring the default
          # value that `initialize_param` emits.
          def optional?
            !!(default || factory || nilable?)
          end

          def type
            copy = @type.gsub(/[[:space:]]+/, "").strip # Remove newlines and spaces
            copy.gsub(",", ", ") # Add a space after each comma
          end

          def rbs?
            @style == "rbs"
          end

          # Translate the prop's Sorbet type to RBS using the `rbi` gem, which
          # understands Sorbet's type syntax and serializes valid RBS (e.g.
          # `T.nilable(String)` -> `String?`, `T.class_of(Foo)` ->
          # `singleton(Foo)`, `T.proc.params(x: Integer).returns(String)` ->
          # `^(Integer x) -> String`). Types `rbi` cannot parse raise and fall
          # back to `untyped` so the annotation stays valid RBS.
          def rbs_type
            RBI::Type.parse_string(@type).rbs_string
          rescue RBI::Type::Error
            "untyped"
          end
        end

        # @!method t_struct?(node)
        def_node_matcher(:t_struct?, <<~PATTERN)
          (const (const {nil? cbase} :T) {:Struct :ImmutableStruct :InexactStruct})
        PATTERN

        # @!method t_props?(node)
        def_node_matcher(:t_props?, "(send nil? {:include :prepend :extend} `(const (const {nil? cbase} :T) :Props))")

        def on_class(node)
          return unless t_struct?(node.parent_class)

          add_offense(node, message: MSG_STRUCT) do |corrector|
            walker = TStructWalker.new(autocorrect_style)
            walker.walk(node.body)

            range = range_between(node.identifier.source_range.end_pos, node.parent_class.source_range.end_pos)
            corrector.remove(range)
            next if node.single_line?

            if rbs? && walker.extend_t_sig_node
              corrector.remove(range_by_whole_lines(walker.extend_t_sig_node.source_range, include_final_newline: true))
            end

            unless walker.has_extend_t_sig || rbs?
              indent = offset(node)
              corrector.insert_after(node.identifier, "\n#{indent}  extend T::Sig\n")
            end

            first_prop = walker.props.first
            walker.props.each do |prop|
              node = prop.node
              indent = offset(node)
              line_range = range_by_whole_lines(prop.node.source_range)
              new_line = prop != first_prop && !previous_line_blank?(node)
              trailing_comments = processed_source.each_comment_in_lines(line_range.line..line_range.line)

              corrector.replace(
                line_range,
                "#{new_line ? "\n" : ""}" \
                  "#{trailing_comments.map { |comment| "#{indent}#{comment.text}\n" }.join}" \
                  "#{indent}#{prop.attr_sig}\n#{indent}#{prop.attr_accessor}",
              )
            end

            last_prop = walker.props.last
            if last_prop
              indent = offset(last_prop.node)
              line_range = range_by_whole_lines(last_prop.node.source_range, include_final_newline: true)
              corrector.insert_after(line_range, initialize_method(indent, walker.props))
            end
          end
        end

        def on_send(node)
          return unless t_props?(node)

          add_offense(node, message: MSG_PROPS)
        end

        private

        def initialize_method(indent, props)
          # We sort optional keyword arguments after required ones
          sorted_props = props.sort_by { |prop| prop.default || prop.factory || prop.nilable? ? 1 : 0 }

          string = +"\n"

          if rbs?
            string << "#{indent}#: (#{sorted_props.map(&:initialize_sig_param).join(", ")}) -> void\n"
          else
            line = "#{indent}sig { params(#{sorted_props.map(&:initialize_sig_param).join(", ")}).void }\n"
            if max_line_length.nil? || line.length <= max_line_length
              string << line
            else
              string << "#{indent}sig do\n"
              string << "#{indent}  params(\n"
              sorted_props.each do |prop|
                string << "#{indent}    #{prop.initialize_sig_param}"
                string << "," if prop != sorted_props.last
                string << "\n"
              end
              string << "#{indent}  ).void\n"
              string << "#{indent}end\n"
            end
          end

          line = "#{indent}def initialize(#{sorted_props.map(&:initialize_param).join(", ")})\n"
          if max_line_length.nil? || line.length <= max_line_length
            string << line
          else
            string << "#{indent}def initialize(\n"
            sorted_props.each do |prop|
              string << "#{indent}  #{prop.initialize_param}"
              string << "," if prop != sorted_props.last
              string << "\n"
            end
            string << "#{indent})\n"
          end

          props.each do |prop|
            string << "#{indent}  #{prop.initialize_assign}\n"
          end
          string << "#{indent}end\n"
        end

        def previous_line_blank?(node)
          processed_source.buffer.source_line(node.source_range.line - 1).blank?
        end

        def autocorrect_style
          config_value = cop_config["AutocorrectStyle"] || "sig"
          unless VALID_AUTOCORRECT_STYLES.include?(config_value)
            raise ArgumentError,
              "Invalid AutocorrectStyle option: '#{config_value}'. Valid options are: #{VALID_AUTOCORRECT_STYLES.join(", ")}"
          end

          config_value
        end

        def rbs?
          autocorrect_style == "rbs"
        end
      end
    end
  end
end
