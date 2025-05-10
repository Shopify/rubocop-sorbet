# frozen_string_literal: true

require "rubocop"

module RuboCop
  module Cop
    module Sorbet
      # Disallow calling `Class.new` with a block.
      #
      # Sorbet incorrectly assumes any methods or constants defined in these blocks
      # are privately defined on `Object`, which can lead to false positives when type-
      # checking (Sorbet may think that a method is defined when it isn't).
      # See https://github.com/sorbet/sorbet/issues/3609#issuecomment-727137772:
      # > Sorbet is somewhat fundamentally incompatible with anonymous classes,
      # > and [Sorbet recommends] avoiding them.
      #
      # @example
      #   # bad
      #   Class.new do
      #     def this_is_bad
      #     end
      #   end
      #
      #   # good
      #   class NamedClass
      #     def this_is_good
      #     end
      #   end
      #
      #   # good
      #   anonymous_class = Class.new
      #   anonymous_class.define_method(:this_is_good) { }
      #
      class AnonymousClassBlock < RuboCop::Cop::Base
        MSG = "Avoid defining anonymous classes with a block."

        def on_send(node)
          return unless class_new_with_block?(node)

          message =
            if (alternative = cop_config["Alternative"])
              "#{MSG} Use `#{alternative}` instead."
            else
              MSG
            end

          add_offense(node, message: message)
        end

        private

        def class_new_with_block?(node)
          return false if (receiver = node.receiver).nil?
          return false unless node.method?(:new) && receiver.const_name == "Class"

          !!node.block_literal?
        end
      end
    end
  end
end
