# encoding: utf-8
# frozen_string_literal: true

require 'rubocop'

# Correct `send` expressions in include statements by constant literals.
#
# Sorbet, the static checker, is not (yet) able to support constructs on the
# following form:
#
# ```ruby
# class MyClass
#   include send_expr
# end
# ```
#
# This cop replaces them by:
#
# ```ruby
# class MyClass
#   MyClassInclude = send_expr
#   include MyClassInclude
# end
# ```
#
# Multiple occurences of this can be found in Shopify's code base like:
#
# ```ruby
# include Rails.application.routes.url_helpers
# ```
# or
# ```ruby
# include Polaris::Engine.helpers
# ```
module RuboCop
  module Cop
    module Sorbet
      class ForbidIncludeConstLiteral < RuboCop::Cop::Cop
        MSG = 'Includes must only contain constant literals'

        attr_accessor :used_names

        def_node_matcher :not_lit_const_include?, <<-PATTERN
          (send nil? {:include :extend :prepend}
            $_
          )
        PATTERN

        def initialize(*)
          super
          self.used_names = Set.new
        end

        def on_send(node)
          return unless not_lit_const_include?(node) do |send_argument|
            ![:const, :self].include?(send_argument.type)
          end
          parent = node.parent
          return unless parent
          parent = parent.parent if [:begin, :block].include?(parent.type)
          return unless [:module, :class, :sclass].include?(parent.type)
          add_offense(node)
        end

        def autocorrect(node)
          lambda do |corrector|
            # Find parent class node
            parent = node.parent
            parent = parent.parent if parent.type == :begin

            # Build include variable name
            class_name = (parent.child_nodes.first.const_name || 'Anon').split('::').last
            include_name = find_free_name("#{class_name}Include")
            used_names << include_name

            # Apply fix
            indent = ' ' * node.loc.column
            fix = "#{include_name} = #{node.child_nodes.first.source}\n#{indent}"
            corrector.insert_before(node.loc.expression, fix)
            corrector.replace(node.child_nodes.first.loc.expression, include_name)
          end
        end

        # Find a free local variable name
        #
        # Since each include uses its own local variable to store the send result,
        # we need to ensure that we don't use the same name twice in the same
        # module.
        def find_free_name(base_name)
          return base_name unless used_names.include?(base_name)
          i = 2
          i += 1 while used_names.include?("#{base_name}#{i}")
          "#{base_name}#{i}"
        end
      end
    end
  end
end
