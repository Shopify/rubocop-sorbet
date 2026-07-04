# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # Shared helper for cops that decide whether a constant assignment
      # (`casgn`) can have its `T.let` annotation safely removed.
      module ConstantScope
        private

        # A constant is statically scoped when it is assigned directly in a
        # class, module, or top-level body, rather than nested inside a
        # conditional, loop, block, or method. In `typed: strict` files Sorbet
        # requires an explicit `T.let` on constants that are not statically
        # scoped (error 7027), so removing the annotation there would break
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
