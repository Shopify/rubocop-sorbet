# frozen_string_literal: true

begin
  gem("rubocop", ">= 1.75.2")
rescue LoadError => error
  warn("rubocop-sorbet requires rubocop >= 1.75.2 and will not load: #{error.message}")
  return
end

require "rubocop"

require_relative "rubocop/sorbet"
require_relative "rubocop/sorbet/version"
require_relative "rubocop/sorbet/plugin"

require_relative "rubocop/cop/sorbet_cops"
