# frozen_string_literal: true

source('https://rubygems.org')
source('https://packages.shopify.io/shopify/gems')
git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

group(:deployment) do
  gem('package_cloud', '~> 0.3.05')
end

# Specify your gem's dependencies in rubocop-sorbet.gemspec
gemspec
