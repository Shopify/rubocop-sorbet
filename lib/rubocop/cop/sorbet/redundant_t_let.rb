# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Prevents unnecessary `T.let` in `initialize` methods. When a signature parameter is assigned to an instance variable, the type is inferred automatically.
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
      class RedundantTLet < RuboCop::Cop::Base
        include SignatureHelp
        extend AutoCorrector

        MSG = "Unnecessary T.let. The instance variable type is inferred from the signature."

        # @!method t_let(node)
        def_node_matcher :t_let, "(ivasgn _ $(send (const {nil? cbase} :T) :let (lvar $_) $_))"

        # @!method sig_params(node)
        def_node_matcher :sig_params, "`(send nil? :params (hash $...))"

        def on_def(node)
          return unless node.method?(:initialize)

          method_args = node.arguments&.to_h { |arg| [arg.name, arg.type] }
          return unless method_args&.any?

          sig_node = node.left_sibling
          return unless sig_node && signature?(sig_node)

          sig_params = sig_params(sig_node)&.to_h { |pair| [pair.key.value, pair.value] }
          return unless sig_params&.any?

          ivar_assignments(node).each do |ivasgn_node|
            t_let(ivasgn_node) do |tlet_node, tlet_key, tlet_value|
              find_redundant_t_let(tlet_node, tlet_key, tlet_value, sig_params, method_args)
            end
          end
        end

        private

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

          arg_type = expected_type(sig_type.source, method_arg_kind)
          return unless tlet_value.source == arg_type

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
