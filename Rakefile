# frozen_string_literal: true

require("bundler/gem_tasks")

Dir["tasks/**/*.rake"].each { |t| load t }

require "rubocop/rake_task"
require "rubocop/cop/minitest_generator"

require "minitest/test_task"

Minitest::TestTask.create(:test) do |test|
  test.test_globs = FileList["test/**/*_test.rb"]
end

task(default: [:documentation_syntax_check, :generate_cops_documentation, :test])

desc("Generate a new cop with a template")
task :new_cop, [:cop] do |_task, args|
  require "rubocop"

  cop_name = args.fetch(:cop) do
    warn('usage: bundle exec rake "new_cop[Department/Name]"')
    exit!
  end

  generator = RuboCop::Cop::Generator.new(cop_name)

  generator.write_source
  generator.write_test
  generator.inject_require(root_file_path: "lib/rubocop/cop/sorbet_cops.rb")
  generator.inject_config(config_file_path: "config/default.yml")

  # We don't use Rubocop's changelog automation workflow
  todo_without_changelog_instruction = generator.todo
    .sub(/$\s+4\. Run.*changelog.*for your new cop\.$/m, "")
    .sub(/^  3./, "  3. Run `bundle exec rake generate_cops_documentation` to generate\n     documentation for your new cop.\n  4.")
  puts todo_without_changelog_instruction
end

module Releaser
  extend Rake::DSL
  extend self

  desc "Prepare a release. The version is read from the VERSION file."
  task :prepare_release do
    version = File.read("VERSION").strip
    puts "Preparing release for version #{version}"

    update_file("lib/rubocop/sorbet/version.rb") do |version_file|
      version_file.sub(/VERSION = ".*"/, "VERSION = \"#{version}\"")
    end

    update_file("config/default.yml") do |default|
      default.gsub(/['"]?<<\s*next\s*>>['"]?/i, "'#{version}'")
    end

    sh "bundle install"
    sh "bundle exec rake generate_cops_documentation"

    sh "git add lib/rubocop/sorbet/version.rb config/default.yml Gemfile.lock VERSION manual"

    puts "git commit -m 'Release #{version}'"
    puts "git push origin main"
    puts "git tag -a v#{version} -m 'Release #{version}'"
    puts "git push origin v#{version}"
  end

  private

  def update_file(path)
    content = File.read(path)
    File.write(path, yield(content))
  end
end
