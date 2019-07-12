# encoding: utf-8
# frozen_string_literal: true

require 'rubocop'

# Correct superclass `send` expressions by constant literals.
#
# Sorbet, the static checker, is not (yet) able to support constructs on the
# following form:
#
# ```ruby
# class Foo < send_expr; end
# ```
#
# This cop replaces them by:
#
# ```ruby
# FooParent = send_expr
# class Foo < FooParent; end
# ```
#
# Multiple occurences of this can be found in Shopify's code base like:
#
# ```ruby
# class ShopScope < Component::TrustedIdScope[ShopIdentity::ShopId]
# ```
# or
# ```ruby
# class ApiClientEligibility < Struct.new(:api_client, :match_results, :shop)
# ```
module RuboCop
  module Cop
    module Sorbet
      class ForbidSuperclassConstLiteral < RuboCop::Cop::Cop
        MSG = 'Superclasses must only contain constant literals'

        def_node_matcher :not_lit_const_superclass?, <<-PATTERN
          (class
            (const ...)
            (send ...)
            ...
          )
        PATTERN

        def on_class(node)
          return unless not_lit_const_superclass?(node)
          add_offense(node.child_nodes[1])
        end

        def autocorrect(node)
          lambda do |corrector|
            class_name = node.parent.child_nodes.first.const_name
            parent_name = "#{class_name}Parent"
            indent = ' ' * node.parent.loc.column
            corrector.insert_before(node.parent.loc.expression, "#{parent_name} = #{node.source}\n#{indent}")
            corrector.replace(node.loc.expression, parent_name)
          end
        end
      end
    end
  end
end
