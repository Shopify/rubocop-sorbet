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
