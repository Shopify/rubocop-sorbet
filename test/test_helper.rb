# frozen_string_literal: true

require "minitest/autorun"
require "rubocop-sorbet"
require "debug/prelude"
require "rubocop/minitest/support"
require "mocha/minitest"

module Minitest
  class Test
    private

    def cop_config(config = {})
      cop_config = RuboCop::ConfigLoader
        .default_configuration.for_cop(target_cop)
        .merge(
          "Enabled" => true, # in case it is 'pending'
          "AutoCorrect" => "always", # in case defaults set it to 'disabled' or false
        ).merge(config)

      hash = { "AllCops" => { "TargetRubyVersion" => ruby_version }, target_cop.cop_name => cop_config }

      RuboCop::Config.new(hash, "#{Dir.pwd}/.rubocop.yml")
    end

    def target_cop
      raise NotImplementedError, "Subclasses must implement this method"
    end
  end
end

RuboCop::ConfigLoader.inject_defaults!("#{__dir__}/../config/default.yml")
