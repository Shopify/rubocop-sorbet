# frozen_string_literal: true

require "rubocop"
require "rbi"

module RuboCop
  module Cop
    module Sorbet
      # Disallows using `T.type_alias` anywhere.
      # Set `AutocorrectToRBS: true` to replace standalone constant assignments with RBS type aliases.
      # Autocorrection is unsafe because it removes the Ruby constant. References to the
      # constant must be migrated separately to the lowercase RBS alias name.
      # Declarations containing RuboCop directives are not autocorrected.
      #
      # @example
      #
      #   # bad
      #   STRING_OR_INTEGER = T.type_alias { T.any(Integer, String) }
      #
      #   # good
      #   #: type string_or_integer = Integer | String
      class ForbidTTypeAlias < RuboCop::Cop::Base
        include RBSAssertionCorrection
        extend AutoCorrector

        MSG = "Do not use `T.type_alias`."

        # @!method t_type_alias?(node)
        def_node_matcher(:t_type_alias?, "(block (call (const nil? :T) :type_alias) _ _)")

        def on_block(node)
          return unless t_type_alias?(node)

          add_offense(node) { |corrector| autocorrect_type_alias(corrector, node) }
        end
        alias_method :on_numblock, :on_block
        alias_method :on_itblock, :on_block

        private

        def autocorrect_type_alias(corrector, node)
          assignment = node.parent
          return unless assignment&.casgn_type? && assignment.children.first.nil?
          return unless standalone_alias?(assignment)
          return unless node.arguments.empty? && node.body
          return unless rbs_assertion_autocorrectable?(node, allow_assignment: true)

          name = assignment.children[1].to_s
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .downcase
          type = ::RBI::Type.parse_string(node.body.source).rbs_string
          declaration = "type #{name} = #{type}"

          range = assignment.source_range
          comments = processed_source.each_comment_in_lines(range.first_line..range.last_line).select do |comment|
            comment.source_range.begin_pos >= range.begin_pos
          end
          return if comments.any? { |comment| comment.text.match?(/\A#[:|]|\brubocop\s*:/) }

          indentation = range.source_line[/\A[ \t]*/]
          replacement = (comments.map(&:text) << "#: #{declaration}").join("\n#{indentation}")
          range = range.join(comments.last.source_range) if comments.last&.source_range&.end_pos.to_i > range.end_pos
          corrector.replace(range, replacement)
        rescue ::RBI::Type::Error
          nil
        end

        def standalone_alias?(assignment)
          parent = assignment.parent
          if parent&.begin_type?
            return false if parent.loc.begin

            parent = parent.parent
          end
          parent.nil? || parent.type?(:class, :module)
        end
      end
    end
  end
end
