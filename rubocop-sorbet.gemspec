
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rubocop/sorbet/version"

Gem::Specification.new do |spec|
  spec.name          = "rubocop-sorbet"
  spec.version       = Rubocop::Sorbet::VERSION
  spec.authors       = ["Ufuk Kayserilioglu"]
  spec.email         = ["ufuk.kayserilioglu@shopify.com"]

  spec.summary       = %q{Automatic Sorbet code style checking tool.}
  spec.homepage      = "https://github.com/shopify/rubocop-sorbet"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/shopify/rubocop-sorbet"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
