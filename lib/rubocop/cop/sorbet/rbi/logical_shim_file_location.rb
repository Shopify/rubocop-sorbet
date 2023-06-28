# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      # This cop ensures RBI shims are located in the same directory as their respective Ruby source file.
      #
      # @example
      #  # bad
      #  # lib/some_file.rbi
      #  # some_file.rbi
      #
      #  # good
      #  # sorbet/shim/some_file.rbi
      class LogicalShimFileLocation < RuboCop::Cop::Base
        include RangeHelp

        MSG = "The shim RBI file path should match the Ruby source file path that it is defined for."

        def investigate
          unless check_component_file_path?
            add_offense(node)
          end
        end

        private

        def check_component_file_path?
          file_name = processed_source.file_path
          file_name[%r{sorbet/rbi/shims/(components/.+\.rb)i}, 1]
        end
      end
    end
  end
end
