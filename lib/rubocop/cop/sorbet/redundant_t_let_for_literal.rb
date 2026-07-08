# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Checks for redundant `T.let` declarations where the first argument
      # is a literal whose type Sorbet can infer automatically, so wrapping
      # it in `T.let` is redundant.
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

        # The frozen-literal and literal-array inference the newer cases rely on
        # was added up to Sorbet 0.6.13304 (frozen regexp via freeze-transparent
        # inference; literal arrays via constant tuple inference). Flagging them
        # against an older Sorbet could remove a `T.let` it still requires, so
        # those paths disable themselves below that version. Bare simple
        # literals (`T.let(3, Integer)`) predate this and are not gated.
        minimum_target_sorbet_static_version "0.6.13304"

        MSG = "Redundant `T.let` for %{type} literal. Sorbet can infer this type automatically."

        # Simple literal node types Sorbet infers, mapped to the class name.
        LITERAL_TYPE_TO_CLASS = {
          dstr: :String,
          float: :Float,
          int: :Integer,
          regexp: :Regexp,
          str: :String,
          sym: :Symbol,
        }.freeze

        # Element node types allowed inside an inferable array literal. These
        # are the literals whose class Sorbet reflects into the array's element
        # type (regexps and ranges, by contrast, degrade the array to
        # `T.untyped` and so are excluded). Interpolated strings (`dstr`) are
        # included: Sorbet infers them as `String`, so an array of them infers
        # the same as an array of plain string literals.
        ARRAY_ELEMENT_TYPES = [:dstr, :str, :sym, :int, :float, :true, :false, :nil].freeze

        # Element node types whose inferred class is unambiguous, used to derive
        # the element type of an unfrozen array literal.
        ELEMENT_TYPE_TO_CLASS = {
          dstr: "String",
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
          # In `typed: strict` files Sorbet requires `T.let` on constants that
          # are not assigned at class/module/top-level scope (e.g. inside an
          # `if` or block), so removing it there would break typechecking.
          return unless statically_scoped?(node)

          t_let_with_literal_and_class?(node) do |value_node, class_name|
            # A frozen regexp (`/foo/.freeze`) is a `send`; its inference
            # requires Sorbet 0.6.13304+. A bare literal is inferable on any
            # version, so only the frozen case is gated.
            frozen = value_node.send_type?
            next if frozen && !enabled_for_sorbet_static_version?

            literal_node = frozen ? value_node.receiver : value_node
            next unless LITERAL_TYPE_TO_CLASS[literal_node.type] == class_name

            register_offense(node, value_node, class_name)
          end

          # Literal-array inference requires Sorbet 0.6.13304+ (see
          # `minimum_target_sorbet_static_version` above).
          return unless enabled_for_sorbet_static_version?

          t_let_with_array?(node) do |value_node, type_node|
            frozen = value_node.send_type?
            array_node = frozen ? value_node.receiver : value_node
            next unless inferable_array?(array_node)

            if frozen
              # A frozen literal array infers as a tuple, a subtype of the
              # annotated T::Array, so the annotation is redundant.
              next unless t_array_type?(type_node)
            else
              # An unfrozen literal array infers as T::Array[<element type>];
              # only redundant when the annotation is exactly that type.
              next unless inferred_array_type(array_node) == normalize(type_node.source)
            end

            register_offense(node, value_node, :Array)
          end
        end

        private

        def register_offense(node, value_node, type)
          t_let_node = node.children[2]
          add_offense(t_let_node, message: format(MSG, type: type)) do |corrector|
            replace_t_let(corrector, t_let_node, value_node)
          end
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
