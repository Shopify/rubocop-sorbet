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

  config.before(:each) do
    config = RuboCop::ConfigLoader.default_configuration
    RuboCop::ConfigLoader.default_configuration = config.merge(rubocop_sorbet_default_file)
  end

  def rubocop_sorbet_default_file
    YAML.load(File.read(File.join(File.dirname(__FILE__), '..', 'config', 'default.yml')))
  end
end
