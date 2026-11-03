# frozen_string_literal: true

require "rbi"

module RuboCop
  module Cop
    module Sorbet
      # Prevents unnecessary `T.let` where Sorbet infers the type automatically.
      #
      # When a signature parameter is assigned to an instance variable in
      # `initialize`, the type is inferred from the signature, whether it is
      # written as a `sig` or as an RBS comment.
      #
      # When a constant is assigned a constructor call (`.new`), optionally
      # followed by `.freeze` (Sorbet 0.6.13304+), the type is inferred from
      # the class being instantiated. Generic classes (e.g. `Set`) are
      # excluded: Sorbet infers their constructor calls as applied types like
      # `T::Set[T.untyped]`, so an annotation is still required.
      #
      # @example
      #
      #  # bad
      #  sig { params(a: Integer) }
      #  def initialize(a)
      #    @a = T.let(a, Integer)
      #  end
      #
      #  # good
      #  sig { params(a: Integer) }
      #  def initialize(a)
      #    @a = a
      #  end
      #
      #  # good
      #  sig { params(a: Integer) }
      #  def initialize(a)
      #    @a = T.let(a, T.any(Integer, String))
      #  end
      #
      #  # bad
      #  #: (Integer) -> void
      #  def initialize(a)
      #    @a = T.let(a, Integer)
      #  end
      #
      #  # good
      #  #: (Integer) -> void
      #  def initialize(a)
      #    @a = a
      #  end
      #
      #  # bad
      #  DEFAULT_PATH = T.let(Pathname.new("/usr/local").freeze, Pathname)
      #
      #  # good
      #  DEFAULT_PATH = Pathname.new("/usr/local").freeze
      #
      #  # good — generic classes are not inferred, so T.let is required
      #  LICENSES = T.let(Set.new(["mit"]).freeze, T::Set[String])
      #
      #  # good — instance variables are only inferred from signature parameters
      #  @path = T.let(Pathname.new("/usr/local"), Pathname)
      class RedundantTLet < RuboCop::Cop::Base
        include SignatureHelp
        include ConstantScope
        include TargetSorbetVersion
        include TLetCorrection
        extend AutoCorrector

        # The constructor-constant inference these cops rely on (`X = A.new`,
        # `X = A.new.freeze`) was finalized by Sorbet's freeze-transparent
        # inference in 0.6.13304. Flagging it against an older Sorbet could
        # remove a `T.let` that Sorbet still requires, so the constant path
        # (`on_casgn`) disables itself below that version. The signature-based
        # instance-variable path (`on_def`) predates this and is not gated.
        minimum_target_sorbet_static_version "0.6.13304"

        MSG = "Unnecessary T.let. The instance variable type is inferred from the signature."
        MSG_CONSTRUCTOR = "Unnecessary T.let. The constant type is inferred from the constructor."

        # Classes whose constructor calls Sorbet infers as applied generic
        # types (e.g. `T::Set[T.untyped]`) rather than the bare class, so
        # constants assigned them still need an explicit annotation.
        GENERIC_CLASSES = ["Array", "Class", "Enumerator", "Hash", "Module", "Range", "Set"].freeze

        # Templates for the collection Sorbet infers for a rest parameter, in
        # each syntax a signature can declare its element type in.
        COLLECTION_TYPES = {
          sorbet: { restarg: "T::Array[%s]", kwrestarg: "T::Hash[Symbol, %s]" }.freeze,
          rbs: { restarg: "Array[%s]", kwrestarg: "Hash[Symbol, %s]" }.freeze,
        }.freeze

        # @!method t_let(node)
        def_node_matcher :t_let, "(ivasgn _ $(send (const {nil? cbase} :T) :let (lvar $_) $_))"

        # @!method t_let_casgn(node)
        def_node_matcher :t_let_casgn, "(casgn _ _ $(send (const {nil? cbase} :T) :let $_ $_))"

        # @!method sig_params(node)
        def_node_matcher :sig_params, "`(send nil? :params (hash $...))"

        def on_def(node)
          return unless node.method?(:initialize)
          # When the def is wrapped by a method modifier (`private def initialize`),
          # Sorbet's initializer rewriter does not process the ivar assignments,
          # so T.let annotations remain required.
          return if node.parent&.send_type?

          method_args = named_argument_types(node)
          return if method_args.none?

          inferred_types, syntax = inferred_parameter_types(node, method_args)
          return if inferred_types.empty?

          ivar_assignments(node).each do |ivasgn_node|
            t_let(ivasgn_node) do |tlet_node, tlet_key, tlet_value|
              find_redundant_t_let(tlet_node, tlet_key, tlet_value, inferred_types, syntax)
            end
          end
        end

        def on_casgn(node)
          return unless enabled_for_sorbet_static_version?
          return unless statically_scoped?(node)

          t_let_casgn(node) do |tlet_node, value_node, type_node|
            next unless type_node.const_type?

            constructor = constructor_call(value_node)
            next unless constructor

            class_path = constructor.receiver.source.delete_prefix("::")
            next if GENERIC_CLASSES.include?(class_path)
            next unless class_path == type_node.source.delete_prefix("::")

            add_offense(tlet_node, message: MSG_CONSTRUCTOR) do |corrector|
              replace_t_let(corrector, tlet_node, value_node)
            end
          end
        end

        private

        # Maps named parameters to their AST types, omitting destructured
        # parameters because they have no name and cannot appear in a signature.
        # For example, `def initialize(a, (left, right), *rest)` returns
        # `{ a: :arg, rest: :restarg }`, omitting `(left, right)`.
        def named_argument_types(method_node)
          method_node.arguments.filter_map do |argument|
            [argument.name, argument.type] if argument.respond_to?(:name)
          end.to_h
        end

        # Returns the `.new` call for a constant constructor, looking through
        # an optional block and trailing `.freeze`. For example,
        # `Foo.new { _1.enabled = true }.freeze` returns the `Foo.new` call,
        # while `foo.new` and `Foo.build` return `nil`.
        def constructor_call(node)
          node = node.receiver if node.send_type? && node.method?(:freeze)
          node = unwrap_block(node)
          return unless node&.send_type? && node.method?(:new)
          return unless node.receiver&.const_type?

          node
        end

        # Returns the method send wrapped by a block, or the original node when
        # no block is present. For example, `Foo.new { _1.enabled = true }`
        # returns the `Foo.new` send node.
        def unwrap_block(node)
          node&.any_block_type? ? node.send_node : node
        end

        def find_sig_node(method_node)
          method_node.left_sibling.then { |s| signature?(s) ? s : nil }
        end

        # The type Sorbet infers for each instance variable assigned from a
        # parameter, keyed by parameter name, with the syntax those types are
        # written in: a `sig` declares Sorbet types, an RBS comment signature
        # declares RBS types, and Sorbet infers from either.
        def inferred_parameter_types(method_node, method_args)
          sig_node = find_sig_node(method_node)
          return [sig_inferred_types(sig_node, method_args), :sorbet] if sig_node

          [rbs_inferred_types(method_node, method_args), :rbs]
        end

        def sig_inferred_types(sig_node, method_args)
          (sig_params(sig_node) || []).filter_map do |pair|
            name = pair.key.value
            arg_kind = method_args[name]
            next unless arg_kind

            [name, inferred_type(normalize_whitespace(pair.value.source), arg_kind, :sorbet)]
          end.to_h
        end

        # Sorbet rejects a repeated signature rather than treating it as an
        # overload, reporting every one but the last as unused, so the last
        # signature is the one it infers from.
        def rbs_inferred_types(method_node, method_args)
          signature = ::RuboCop::Sorbet::RBSParser.rbs_signatures_before(processed_source, method_node).last
          return {} unless signature

          signature.parameter_types(method_node.arguments).to_h do |name, type|
            [name, inferred_type(type, method_args[name], :rbs)]
          end
        end

        def normalize_whitespace(source)
          source
            .gsub(/\s+/, " ")              # collapse all whitespace to single spaces
            .gsub(/,\s*([)\]\}])/, "\\1")  # remove trailing commas before closing delimiters
            .gsub(/,\s*/, ", ")            # normalize to a single space after commas
            .gsub(/\(\s*/, "(")            # remove space after (
            .gsub(/\s*\)/, ")")            # remove space before )
            .gsub(/\[\s*/, "[")            # remove space after [
            .gsub(/\s*\]/, "]")            # remove space before ]
            .strip
        end

        def ivar_assignments(node)
          return [] unless node.body
          return node.body.each_child_node(:ivasgn) if node.body.begin_type?
          return [node.body] if node.body.ivasgn_type?

          []
        end

        def find_redundant_t_let(node, tlet_key, tlet_value, inferred_types, syntax)
          inferred = inferred_types[tlet_key]
          return unless inferred
          return unless normalize_t_let_type(tlet_value.source, syntax) == inferred

          add_offense(node) do |corrector|
            corrector.replace(node, tlet_key.to_s)
          end
        end

        # The type Sorbet infers for a parameter, in `syntax`. A rest parameter's
        # signature declares its element type, so the inferred type is the
        # collection wrapping it.
        def inferred_type(declared_type, arg_kind, syntax)
          collection = COLLECTION_TYPES.fetch(syntax)[arg_kind]
          collection ? format(collection, declared_type) : declared_type
        end

        # The `T.let` type, written in `syntax` so it can be compared to the
        # inferred type. Returns nil when it is not a valid Sorbet type.
        def normalize_t_let_type(source, syntax)
          return normalize_whitespace(source) if syntax == :sorbet

          ::RBI::Type.parse_string(source).rbs_string
        rescue ::RBI::Type::Error
          nil
        end
      end
    end
  end
end
