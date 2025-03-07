# frozen_string_literal: true

require "rubocop"

require_relative "rubocop/sorbet"
require_relative "rubocop/sorbet/version"
require_relative "rubocop/sorbet/plugin"

unless RuboCop::Sorbet::Plugin::SUPPORTED
  require_relative "rubocop/sorbet/inject"
  RuboCop::Sorbet::Inject.defaults!
end

require_relative "rubocop/cop/sorbet_cops"
