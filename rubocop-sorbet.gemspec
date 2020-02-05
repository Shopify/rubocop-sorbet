# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'rubocop-sorbet'
  spec.version       = '0.3.5'
  spec.authors       = ['Ufuk Kayserilioglu', 'Alan Wu', 'Alexandre Terrasa', 'Peter Zhu']
  spec.email         = ['ruby@shopify.com']

  spec.summary       = 'Automatic Sorbet code style checking tool.'
  spec.homepage      = 'https://github.com/shopify/rubocop-sorbet'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/shopify/rubocop-sorbet'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    %x(git ls-files -z).split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency('rspec', '~> 3.7')
  spec.add_development_dependency('unparser', '~> 0.4.2')
  spec.add_development_dependency('rubocop', '~> 0.57')
end
