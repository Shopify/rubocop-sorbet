# frozen_string_literal: true

require 'rubocop_sorbet'
require 'rubocop/rspec/support'

RSpec.configure do |config|
  config.include(RuboCop::RSpec::ExpectOffense)

  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random
  Kernel.srand(config.seed)

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end
end
