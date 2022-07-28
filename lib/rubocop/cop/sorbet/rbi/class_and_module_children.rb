# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      class ClassAndModuleChildren < RuboCop::Cop::Style::ClassAndModuleChildren
        def style
          :compact
        end

        def on_class(node)
          return if node.parent_class && style != :nested

          check_style(node, node.body)
        end

        def check_compact_style(node, body)
          if body&.begin_type?
            body.children.each do |child|
              check_compact_style(node, child) if %i[module class].include?(child.type)
            end
          else
            super
          end
        end

        # def needs_compacting?(body)
        #   body && %i[begin module class].include?(body.type)
        # end
      end
    end
  end
end
