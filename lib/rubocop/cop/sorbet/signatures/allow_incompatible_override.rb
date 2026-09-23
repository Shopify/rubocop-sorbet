# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallows incompatible overrides in Sorbet signatures and RBS comments.
      # Using `allow_incompatible` suggests a violation of the Liskov
      # Substitution Principle, meaning that a subclass is not a valid
      # subtype of its superclass. This Cop prevents these design smells
      # from occurring.
      #
      # @example
      #
      #   # bad
      #   sig { override(allow_incompatible: true).void }
      #   def foo; end
      #
      #   # @override(allow_incompatible: true)
      #   #: () -> void
      #   def foo; end
      #
      #   # @override(allow_incompatible: true)
      #   #: String
      #   attr_reader :foo
      #
      #   # good
      #   sig { override.void }
      #
      #   # @override
      #   #: () -> void
      #   def foo; end
      class AllowIncompatibleOverride < RuboCop::Cop::Base
        MSG = "Usage of `allow_incompatible` suggests a violation of the Liskov Substitution Principle. " \
          "Instead, strive to write interfaces which respect subtyping principles and remove `allow_incompatible`"
        RBS_ALLOW_INCOMPATIBLE_OVERRIDE = /\A#\s*@override\(\s*(allow_incompatible\s*:\s*true)\s*\)\s*\z/
        RBS_ATTRIBUTE_METHODS = [:attr_reader, :attr_writer, :attr_accessor].freeze
        RESTRICT_ON_SEND = [:override, :attr_reader, :attr_writer, :attr_accessor].freeze

        # @!method sig_dot_override?(node)
        def_node_matcher(:sig_dot_override?, <<~PATTERN)
          (send
            [!nil? #sig?]
            :override
            (hash <$(pair (sym :allow_incompatible) true) ...>)
          )
        PATTERN

        # @!method sig?(node)
        def_node_search(:sig?, <<~PATTERN)
          (send _ :sig ...)
        PATTERN

        # @!method override?(node)
        def_node_matcher(:override?, <<~PATTERN)
          (send
            _
            :override
            (hash <$(pair (sym :allow_incompatible) true) ...>)
          )
        PATTERN

        def on_def(node)
          check_rbs_annotations(node)
        end

        alias_method :on_defs, :on_def

        def on_send(node)
          if RBS_ATTRIBUTE_METHODS.include?(node.method_name)
            check_rbs_annotations(node)
          else
            sig_dot_override?(node) do |allow_incompatible_pair|
              add_offense(allow_incompatible_pair)
            end
          end
        end

        def on_block(node)
          return unless sig?(node.send_node)

          block = node.children.last
          return unless block&.send_type?

          receiver = block.receiver
          while receiver
            allow_incompatible_pair = override?(receiver)
            if allow_incompatible_pair
              add_offense(allow_incompatible_pair)
              break
            end
            receiver = receiver.receiver
          end
        end

        alias_method :on_numblock, :on_block
        alias_method :on_itblock, :on_block

        private

        def check_rbs_annotations(node)
          ::RuboCop::Sorbet::RBSParser.rbs_annotations_before(processed_source, node).each do |comment|
            match = comment.text.match(RBS_ALLOW_INCOMPATIBLE_OVERRIDE)
            next unless match

            begin_pos = comment.source_range.begin_pos + match.begin(1)
            end_pos = comment.source_range.begin_pos + match.end(1)
            add_offense(comment.source_range.with(begin_pos: begin_pos, end_pos: end_pos))
          end
        end
      end
    end
  end
end
