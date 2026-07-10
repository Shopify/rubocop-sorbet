# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Shared helper for cops that unwrap a `T.let` on a constant assignment.
      module ConstantScope
        private

        # True when the constant is assigned directly in a class, module, or
        # top-level body. In `typed: strict` files Sorbet requires a `T.let` on
        # constants assigned elsewhere (inside a conditional, loop, block, or
        # method — error 7027), so removing the annotation there would break
        # typechecking.
        def statically_scoped?(node)
          ancestor = node.parent
          ancestor = ancestor.parent if ancestor&.begin_type?
          ancestor.nil? || ancestor.class_type? || ancestor.module_type? || ancestor.sclass_type?
        end
      end
    end
  end
end
