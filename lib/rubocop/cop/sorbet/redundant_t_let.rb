# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Prevents unnecessary `T.let` where Sorbet infers the type automatically.
      #
      # When a signature parameter is assigned to an instance variable in
      # `initialize`, the type is inferred from the signature.
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
        extend AutoCorrector

        MSG = "Unnecessary T.let. The instance variable type is inferred from the signature."
        MSG_CONSTRUCTOR = "Unnecessary T.let. The constant type is inferred from the constructor."

        # Classes whose constructor calls Sorbet infers as applied generic
        # types (e.g. `T::Set[T.untyped]`) rather than the bare class, so
        # constants assigned them still need an explicit annotation.
        GENERIC_CLASSES = ["Array", "Class", "Enumerator", "Hash", "Module", "Range", "Set"].freeze

        # @!method t_let(node)
        def_node_matcher :t_let, "(ivasgn _ $(send (const {nil? cbase} :T) :let (lvar $_) $_))"

        # @!method t_let_casgn(node)
        def_node_matcher :t_let_casgn, "(casgn _ _ $(send (const {nil? cbase} :T) :let $_ $_))"

        # @!method sig_params(node)
        def_node_matcher :sig_params, "`(send nil? :params (hash $...))"

        def on_def(node)
          return unless node.method?(:initialize)

          method_args = node.arguments&.to_h { |arg| [arg.name, arg.type] }
          return unless method_args&.any?

          sig_node = find_sig_node(node)
          return unless sig_node

          sig_params = sig_params(sig_node)&.to_h { |pair| [pair.key.value, pair.value] }
          return unless sig_params&.any?

          ivar_assignments(node).each do |ivasgn_node|
            t_let(ivasgn_node) do |tlet_node, tlet_key, tlet_value|
              find_redundant_t_let(tlet_node, tlet_key, tlet_value, sig_params, method_args)
            end
          end
        end

        def on_casgn(node)
          t_let_casgn(node) do |tlet_node, value_node, type_node|
            next unless type_node.const_type?

            constructor = constructor_call(value_node)
            next unless constructor

            class_path = constructor.receiver.source.delete_prefix("::")
            next if GENERIC_CLASSES.include?(class_path)
            next unless class_path == type_node.source.delete_prefix("::")

            add_offense(tlet_node, message: MSG_CONSTRUCTOR) do |corrector|
              corrector.replace(tlet_node, value_node.source)
            end
          end
        end

        private

        def constructor_call(node)
          node = node.receiver if node.send_type? && node.method?(:freeze)
          # `Foo.new { ... }` is a block node wrapping the `.new` send.
          node = node.send_node if node&.block_type?
          return unless node&.send_type? && node.method?(:new)
          return unless node.receiver&.const_type?

          node
        end

        def find_sig_node(method_node)
          # When the def is wrapped by a method modifier (`private def initialize`),
          # Sorbet's initializer rewriter does not process the ivar assignments,
          # so T.let annotations remain required. Skip by returning nil.
          return if method_node.parent&.send_type?

          method_node.left_sibling.then { |s| signature?(s) ? s : nil }
        end

        def normalize_whitespace(source)
          source
            .gsub(/\s+/, " ")              # collapse all whitespace to single spaces
            .gsub(/,\s*([)\]\}])/, "\\1")  # remove trailing commas before closing delimiters
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

        def find_redundant_t_let(node, tlet_key, tlet_value, sig_params, method_args)
          sig_type = sig_params[tlet_key]
          return unless sig_type

          method_arg_kind = method_args[tlet_key]
          return unless method_arg_kind

          arg_type = expected_type(normalize_whitespace(sig_type.source), method_arg_kind)
          return unless normalize_whitespace(tlet_value.source) == arg_type

          add_offense(node) do |corrector|
            corrector.replace(node, tlet_key.to_s)
          end
        end

        def expected_type(sig_type, arg_kind)
          case arg_kind
          when :restarg then "T::Array[#{sig_type}]"
          when :kwrestarg then "T::Hash[Symbol, #{sig_type}]"
          else sig_type
          end
        end
      end
    end
  end
end
