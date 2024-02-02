# frozen_string_literal: true

module RuboCop
  module Cop
    module Sorbet
      module RBIVersionAnnotationHelper
        VERSION_PREFIX = "# @version "

        def rbi_version_annotations
          processed_source.comments.select do |comment|
            version_annotation?(comment)
          end
        end

        private

        def version_annotation?(comment)
          comment.text.start_with?(VERSION_PREFIX)
        end

        def versions(comment)
          comment.text.delete_prefix(VERSION_PREFIX).split(", ")
        end
      end
    end
  end
end
