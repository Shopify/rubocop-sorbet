# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Checks for redundant `T.let` declarations and trailing RBS annotations
      # where the assigned value is a literal whose type Sorbet can infer
      # automatically.
      #
      # Simple literals (strings, symbols, integers, floats, regexps) infer as
      # their own class. Regexp literals are the only simple literals whose
      # inference survives a `.freeze` call (Sorbet 0.6.13304+), so
      # `T.let(/foo/.freeze, Regexp)` is also redundant; other frozen simple
      # literals (e.g. `"hello".freeze`) are not inferred and still need `T.let`.
      #
      # Array literals of simple literals are also inferred:
      #
      # * A frozen array (`[...].freeze`) infers as a fixed-size tuple, which is
      #   a subtype of the annotated `T::Array`, so the annotation is redundant.
      # * An unfrozen array infers as `T::Array[<element type>]`. It is only
      #   flagged when that inferred type matches the annotation exactly, to
      #   avoid silently widening (e.g. `["a", nil]` infers a nilable element).
      #
      # Hashes are excluded: Sorbet infers hash literals as `T.untyped`, so the
      # annotation is required.
      #
      # @example
      #   # bad
      #   MAX_RETRIES = T.let(3, Integer)
      #   GREETING = T.let("hello", String)
      #   RATE = T.let(1.5, Float)
      #   PATTERN = T.let(/foo/, Regexp)
      #   FROZEN_PATTERN = T.let(/foo/.freeze, Regexp)
      #   STATUS = T.let(:active, Symbol)
      #   SHELLS = T.let([:bash, :zsh].freeze, T::Array[Symbol])
      #   NAMES = T.let(["alice", "bob"], T::Array[String])
      #   RBS_GREETING = "hello" #: String
      #   RBS_NAMES = ["alice", "bob"] #: Array[String]
      #
      #   # good
      #   MAX_RETRIES = 3
      #   GREETING = "hello"
      #   RATE = 1.5
      #   PATTERN = /foo/
      #   FROZEN_PATTERN = /foo/.freeze
      #   STATUS = :active
      #   SHELLS = [:bash, :zsh].freeze
      #   NAMES = ["alice", "bob"]
      #   RBS_GREETING = "hello"
      #   RBS_NAMES = ["alice", "bob"]
      #
      #   # good — non-regexp frozen simple literals are not inferred
      #   GREETING = T.let("hello".freeze, String)
      #
      #   # good — hash literals are inferred as T.untyped
      #   OPTIONS = T.let({ verbose: true }, T::Hash[Symbol, T::Boolean])
      #
      #   # good — unfrozen array whose annotation is wider than the inferred type
      #   NAMES = T.let(["alice", "bob"], T::Array[T.nilable(String)])
      #
      #   # good — type is not the literal's own class
      #   value = T.let("hello", T.nilable(String))
      #
      #   # good — instance variables need T.let for Sorbet to track their type
      #   @max_retries = T.let(3, Integer)
      #
      #   # good — local variables may need T.let so Sorbet allows reassignment
      #   count = T.let(0, Integer)
      class RedundantTLetForLiteral < Base
        include ConstantScope
        include TargetSorbetVersion
        include TLetCorrection
        extend AutoCorrector

        # Frozen-literal and literal-array inference require Sorbet 0.6.13304 or
        # newer. Those paths disable themselves for older targets, while bare
        # simple literals predate that version and remain eligible for both
        # `T.let` and RBS annotations.
        minimum_target_sorbet_static_version "0.6.13304"

        MSG = "Redundant %{annotation} for %{type} literal. Sorbet can infer this type automatically."
        RBS_ANNOTATION = /\A#\s*:\s*(?<type>.+?)\s*\z/

        # Simple literal node types Sorbet infers, mapped to the class name.
        # Interpolated strings/symbols (`dstr`/`dsym`) infer as `String`/`Symbol`.
        LITERAL_TYPE_TO_CLASS = {
          dstr: :String,
          dsym: :Symbol,
          float: :Float,
          int: :Integer,
          regexp: :Regexp,
          str: :String,
          sym: :Symbol,
        }.freeze

        # Element node types allowed inside an inferable array literal: the
        # literals whose class Sorbet reflects into the array's element type.
        # Regexps and ranges, by contrast, degrade the array to `T.untyped`, so
        # they are excluded. Interpolated strings/symbols (`dstr`/`dsym`) infer
        # as `String`/`Symbol`, the same as their plain literal forms.
        ARRAY_ELEMENT_TYPES = [:dstr, :dsym, :str, :sym, :int, :float, :true, :false, :nil].freeze

        # Element node types whose inferred class is unambiguous, used to derive
        # the element type of an unfrozen array literal.
        ELEMENT_TYPE_TO_CLASS = {
          dstr: "String",
          dsym: "Symbol",
          float: "Float",
          int: "Integer",
          str: "String",
          sym: "Symbol",
        }.freeze

        # @!method t_let_with_literal_and_class?(node)
        def_node_matcher :t_let_with_literal_and_class?, <<~PATTERN
          (casgn _ _ (send (const {nil? cbase} :T) :let ${literal? (send (regexp ...) :freeze)} (const nil? $_)))
        PATTERN

        # @!method t_let_with_array?(node)
        def_node_matcher :t_let_with_array?, <<~PATTERN
          (casgn _ _ (send (const {nil? cbase} :T) :let ${array (send array :freeze)} $_))
        PATTERN

        def on_casgn(node)
          return unless statically_scoped?(node)

          t_let_with_literal_and_class?(node) do |value_node, class_name|
            literal_node = inferable_literal_node(value_node)
            next unless literal_node
            next unless LITERAL_TYPE_TO_CLASS[literal_node.type] == class_name

            register_offense(node, value_node, class_name)
          end

          if enabled_for_sorbet_static_version?
            t_let_with_array?(node) do |value_node, type_node|
              frozen = value_node.send_type?
              array_node = frozen ? value_node.receiver : value_node
              next unless inferable_array?(array_node)
              next unless redundant_array_annotation?(array_node, type_node, frozen: frozen)

              register_offense(node, value_node, :Array)
            end
          end

          check_rbs_annotation(node)
        end

        private

        # Returns the underlying literal when its inference is supported by the
        # target Sorbet version. Bare literals return themselves. A frozen value
        # returns its receiver only for regexps, whose inference survives
        # `.freeze` on supported targets.
        def inferable_literal_node(value_node)
          return value_node unless value_node.send_type?
          return unless value_node.method?(:freeze) && value_node.receiver&.regexp_type?
          return unless enabled_for_sorbet_static_version?

          value_node.receiver
        end

        def register_offense(node, value_node, type)
          t_let_node = node.children[2]
          add_offense(t_let_node, message: format(MSG, annotation: "`T.let`", type: type)) do |corrector|
            replace_t_let(corrector, t_let_node, value_node)
          end
        end

        def check_rbs_annotation(node)
          value_node = node.children[2]
          comment, annotated_type = trailing_rbs_annotation(node)
          return unless comment

          literal_node = inferable_literal_node(value_node)
          if literal_node
            inferred_type = LITERAL_TYPE_TO_CLASS[literal_node.type]
            if inferred_type
              return unless annotated_type.delete_prefix("::") == inferred_type.to_s

              return register_rbs_offense(node, comment, inferred_type)
            end
          end

          return unless enabled_for_sorbet_static_version?

          frozen = value_node.send_type? && value_node.method?(:freeze)
          array_node = frozen ? value_node.receiver : value_node
          return unless inferable_array?(array_node)
          return unless redundant_rbs_array_annotation?(array_node, annotated_type, frozen: frozen)

          register_rbs_offense(node, comment, :Array)
        end

        def trailing_rbs_annotation(node)
          last_line = node.source_range.last_line
          comment = processed_source.each_comment_in_lines(last_line..last_line).find do |candidate|
            next false if candidate.source_range.begin_pos < node.source_range.end_pos

            gap = processed_source.buffer.source[node.source_range.end_pos...candidate.source_range.begin_pos]
            gap.match?(/\A[ \t]*\z/)
          end
          return unless comment

          match = RBS_ANNOTATION.match(comment.text)
          return unless match

          [comment, normalize(match[:type])]
        end

        def register_rbs_offense(node, comment, type)
          add_offense(comment, message: format(MSG, annotation: "RBS annotation", type: type)) do |corrector|
            range = comment.source_range.with(begin_pos: node.source_range.end_pos)
            corrector.remove(range)
          end
        end

        def redundant_rbs_array_annotation?(array_node, type, frozen:)
          rbs_type = type.delete_prefix("::")
          return rbs_type.match?(/\AArray\[(?:.+)\]\z/) if frozen

          inferred_array_type(array_node)&.delete_prefix("T::") == rbs_type
        end

        # An array literal is inferable only when every element is one of the
        # simple literals Sorbet reflects into the element type (or a nested
        # inferable array). Empty arrays are excluded: they infer as
        # `T::Array[T.untyped]` and so still need the annotation.
        def inferable_array?(node)
          return false unless node.array_type?
          return false if node.children.empty?

          node.children.all? do |child|
            if child.array_type?
              inferable_array?(child)
            else
              ARRAY_ELEMENT_TYPES.include?(child.type)
            end
          end
        end

        # Returns whether Sorbet's inferred array type makes the annotation
        # redundant. A frozen `[:a].freeze` infers as a tuple compatible with
        # any `T::Array[...]`; an unfrozen `[:a]` must infer exactly the
        # annotated type, such as `T::Array[Symbol]`.
        def redundant_array_annotation?(array_node, type_node, frozen:)
          return t_array_type?(type_node) if frozen

          inferred_array_type(array_node) == normalize(type_node.source).delete_prefix("::")
        end

        # `T::Array[...]` (with or without a leading `::`)
        def t_array_type?(node)
          node.send_type? && node.method?(:[]) &&
            node.receiver&.source&.delete_prefix("::") == "T::Array"
        end

        # The type Sorbet infers for an unfrozen array literal, or nil when the
        # element types are not uniform enough to render deterministically
        # (mixed classes, booleans, nils and nested arrays are left alone).
        def inferred_array_type(node)
          classes = node.children.map { |child| ELEMENT_TYPE_TO_CLASS[child.type] }
          return unless classes.all? && classes.uniq.size == 1

          "T::Array[#{classes.first}]"
        end

        # Strips whitespace and any trailing comma before a closing delimiter,
        # so a multi-line annotation (`T::Array[\n  String,\n]`) still compares
        # equal to the rendered inferred type.
        def normalize(source)
          source.gsub(/\s+/, "").gsub(/,([)\]}])/, '\1')
        end
      end
    end
  end
end
