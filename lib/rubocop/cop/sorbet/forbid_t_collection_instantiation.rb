# frozen_string_literal: true

require "rbi"

module RuboCop
  module Cop
    module Sorbet
      # Disallows instantiating Sorbet collection types. Instantiate the Ruby
      # collection directly and declare its type separately when needed.
      #
      # Checks `T::Array`, `T::Hash`, `T::Set`, `T::Range`,
      # `T::Enumerator`, `T::Enumerator::Lazy`, and `T::Enumerator::Chain`,
      # with or without type arguments.
      #
      # Set `AutocorrectToRBS: true` to replace standalone or assigned constructors
      # with Ruby constructors and RBS inline type annotations. Calls with an
      # existing RBS annotation or an untranslatable type are not autocorrected.
      # Empty Array and Hash constructors use literals unless arguments, blocks,
      # or comments inside the call need to be preserved.
      #
      # @safety
      #   Autocorrection removes runtime evaluation of type arguments and changes
      #   constant lookup. RBS annotations require an RBS-aware type checker.
      #
      # @example
      #   # bad
      #   T::Array[String].new
      #   T::Hash[Symbol, Integer].new
      #   T::Set[String].new
      #   T::Array.new
      #
      #   # good
      #   Array.new
      #   Hash.new
      #   Set.new
      #   T.let(Array.new, T::Array[String])
      #   Set.new #: Set[String]
      #
      # @example AutocorrectToRBS: true
      #   # bad
      #   arr = T::Array[String].new
      #   items = T::Set[T.nilable(String)].new(values)
      #
      #   # good
      #   arr = [] #: Array[String]
      #   items = Set.new(values) #: Set[String?]
      class ForbidTCollectionInstantiation < Base
        include RBSAssertionCorrection
        extend AutoCorrector

        MSG = "Instantiate Ruby collections directly instead of Sorbet collection types."
        RESTRICT_ON_SEND = [:new].freeze

        # @!method t_collection?(node)
        def_node_matcher :t_collection?, <<~PATTERN
          {
            (const (const {nil? cbase} :T) {:Array :Hash :Set :Range :Enumerator})
            (const (const (const {nil? cbase} :T) :Enumerator) {:Lazy :Chain})
          }
        PATTERN

        def on_send(node)
          receiver = node.receiver
          return unless receiver

          type = receiver.send_type? && receiver.method?(:[]) ? receiver.receiver : receiver
          return unless t_collection?(type)

          add_offense(receiver) { |corrector| autocorrect_to_rbs(corrector, node, type) }
        end
        alias_method :on_csend, :on_send

        private

        def autocorrect_to_rbs(corrector, node, type)
          expression = node.block_node || node
          return unless rbs_assertion_autocorrectable?(expression, allow_assignment: true)
          return if comments_within?(node.receiver)

          ruby_class = type.const_name.delete_prefix("T::")
          ruby_class = "::#{ruby_class}" if type.source.start_with?("::")
          if node.receiver.send_type?
            arguments = node.receiver.arguments.map { |argument| ::RBI::Type.parse_string(argument.source).rbs_string }
            annotation = "#{ruby_class}[#{arguments.join(", ")}]"
            corrector.insert_after(expression, " #: #{annotation}")
          end
          literal = empty_collection_literal(node, type)
          if literal
            corrector.replace(node, literal)
          else
            corrector.replace(node.receiver, ruby_class)
          end
        rescue ::RBI::Type::Error
          nil
        end

        def empty_collection_literal(node, type)
          return unless node.arguments.empty? && !node.block_node
          return if comments_within?(node)

          case type.short_name
          when :Array then "[]"
          when :Hash then "{}"
          end
        end
      end
    end
  end
end
