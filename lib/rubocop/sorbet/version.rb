# frozen_string_literal: true

module RuboCop
  module Sorbet
    VERSION = File.read(File.expand_path("../../../../VERSION", __FILE__)).strip
  end
end
