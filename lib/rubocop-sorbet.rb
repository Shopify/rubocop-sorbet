# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/sorbet"
require_relative "rubocop/sorbet/version"
require_relative "rubocop/sorbet/plugin"

unless defined?(RuboCop::Sorbet::Plugin)
  require_relative "rubocop/sorbet/inject"
  RuboCop::Sorbet::Inject.defaults!
end

require_relative "rubocop/cop/sorbet_cops"
