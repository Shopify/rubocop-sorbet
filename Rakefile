# frozen_string_literal: true

require("bundler/gem_tasks")

Dir["tasks/**/*.rake"].each { |t| load t }

require "rubocop/rake_task"

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
  generator.write_spec
  generator.inject_require(root_file_path: "lib/rubocop/cop/sorbet_cops.rb")
  generator.inject_config(config_file_path: "config/default.yml")

  # We don't use Rubocop's changelog automation workflow
  todo_without_changelog_instruction = generator.todo
    .sub(/$\s+4\. Run.*changelog.*for your new cop\.$/m, "")
  puts todo_without_changelog_instruction
end
