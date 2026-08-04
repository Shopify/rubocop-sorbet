# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Checks that setter methods (methods whose name ends with `=`)
      # declare a `void` return type, in either a Sorbet `sig` block or an
      # RBS inline comment signature.
      #
      # Sorbet requires setter methods to return `void`. Declaring any other
      # return type violates the setter contract and is rejected by Sorbet
      # under `#typed: strict` and above.
      #
      # @example
      #
      #   # bad
      #   sig { params(name: String).returns(String) }
      #   def name=(name); end
      #
      #   # good
      #   sig { params(name: String).void }
      #   def name=(name); end
      #
      #   # bad
      #   #: (String) -> String
      #   def name=(name); end
      #
      #   # good
      #   #: (String) -> void
      #   def name=(name); end
      #
      #   # bad
      #   #: (
      #   #|   String name
      #   #| ) -> String
      #   def name=(name); end
      #
      #   # good
      #   #: (
      #   #|   String name
      #   #| ) -> void
      #   def name=(name); end
      #
      class SetterReturnType < ::RuboCop::Cop::Base
        include SignatureHelp
        include RangeHelp
        extend AutoCorrector

        MSG = "Setter methods must declare a `void` return type."

        NON_SETTER_OPERATORS = ["==", "===", "!=", "<=", ">="].freeze

        def on_def(node)
          check(node)
        end
        alias_method :on_defs, :on_def

        private

        def check(node)
          return unless setter?(node)

          target = outermost_send_ancestor(node)
          sigs = preceding_sigs(target)
          if sigs.any?
            sigs.each { |sig| check_sig(sig) }
          else
            check_rbs(target)
          end
        end

        def setter?(node)
          name = node.method_name.to_s
          name.end_with?("=") && !NON_SETTER_OPERATORS.include?(name)
        end

        # Climb past `private`/`public`/`protected` and other send wrappers so
        # sig/RBS lookup runs against the real surrounding siblings rather than
        # the send's other arguments.
        def outermost_send_ancestor(node)
          node = node.parent while node.parent&.send_type?
          node
        end

        # The `sig` blocks immediately preceding `target` among its siblings,
        # supporting consecutive overload sigs. The scan stops at the first
        # non-signature sibling so a setter never inherits another method's sig.
        def preceding_sigs(target)
          parent = target.parent
          return [] unless parent

          siblings = parent.children
          index = siblings.index { |sibling| sibling.equal?(target) }
          sigs = []
          siblings[0...index].reverse_each do |sibling|
            break unless sibling && signature?(sibling)

            sigs.unshift(sibling)
          end
          sigs
        end

        def check_sig(sig)
          decl = return_declaration(sig.body)
          return unless decl # incomplete signature: nothing declared to check
          return if decl.method?(:void)

          return unless decl.first_argument # malformed returns

          sig_return_range = sig_return_range(decl)

          add_offense(sig_return_range) do |corrector|
            corrector.replace(sig_return_range, "void")
          end
        end

        # Walks the receiver chain of the sig body (the builder call chain)
        # and returns the outermost `void` or `returns` node, so a `void` or
        # `returns` nested inside a type argument (e.g. `T.proc.void`) is not
        # mistaken for the method's return declaration.
        def return_declaration(node)
          return unless node&.send_type?

          if node.method?(:void) || node.method?(:returns)
            node
          else
            return_declaration(node.receiver)
          end
        end

        # Range covering `returns(TYPE)` (selector through the closing
        # paren / last argument), to be replaced with `void`.
        def sig_return_range(returns_node)
          end_pos = returns_node.loc.end&.end_pos
          end_pos ||= returns_node.last_argument&.source_range&.end_pos
          end_pos ||= returns_node.loc.selector.end_pos
          range_between(returns_node.loc.selector.begin_pos, end_pos)
        end

        def check_rbs(node)
          ::RuboCop::Sorbet::RBSParser.rbs_signatures_before(processed_source, node).each do |comments|
            range = ::RuboCop::Sorbet::RBSParser.return_type_range(processed_source, comments)
            next unless range

            offense_range, replace_range = range
            add_offense(offense_range) do |corrector|
              corrector.replace(replace_range, "void")
            end
          end
        end
      end
    end
  end
end
