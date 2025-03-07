# frozen_string_literal: true

# The original code is from https://github.com/rubocop-hq/rubocop-rspec/blob/master/lib/rubocop/rspec/inject.rb
# See https://github.com/rubocop-hq/rubocop-rspec/blob/master/MIT-LICENSE.md
module RuboCop
  module Sorbet
    # Because RuboCop doesn't yet support plugins, we have to monkey patch in a
    # bit of our configuration.
    module Inject
      class << self
        def defaults!
          path = CONFIG_DEFAULT.to_s
          hash = ConfigLoader.send(:load_yaml_configuration, path)
          if Gem::Version.new(RuboCop::Version::STRING) >= Gem::Version.new("1.66")
            # We use markdown for cop documentation. Unconditionally setting
            # the base url will produce incorrect urls on older RuboCop versions,
            # so we do that for fully supported version only here.
            hash["Sorbet"] ||= {}
            hash["Sorbet"]["DocumentationBaseURL"] = "https://github.com/Shopify/rubocop-sorbet/blob/main/manual"
            hash["Sorbet"]["DocumentationExtension"] = ".md"
          end
          config = Config.new(hash, path).tap(&:make_excludes_absolute)
          puts "configuration from #{path}" if ConfigLoader.debug?
          config = ConfigLoader.merge_with_default(config, path)
          ConfigLoader.instance_variable_set(:@default_configuration, config)
        end
      end
    end
  end
end
