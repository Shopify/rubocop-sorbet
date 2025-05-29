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

  if args[:cop].nil? || !args[:cop].match?(%r`[^/]+/[^/]+`)
    warn('usage: bundle exec rake "new_cop[Department/Name]"')
    exit!
  end

  generator = RuboCop::Cop::Generator.new(args[:cop])
  badge = RuboCop::Cop::Badge.parse(args[:cop])

  generator.write_source

  path = File.join("test/rubocop/cop", "#{Bundler::Thor::Util.snake_case(badge.to_s)}_test.rb")
  if File.exist?(path)
    warn "rake new_cop: #{path} already exists!"
    exit!
  end

  File.write(path, <<~TEST)
    # frozen_string_literal: true

    require "test_helper"

    module RuboCop
      module Cop
        module #{badge.department_name.gsub("/", "::")}
          class #{badge.cop_name}Test < ::Minitest::Test
            MSG = "#{badge}: TODO: Write a meaningful message for this cop."

            def setup
              @cop = #{badge.cop_name}.new
            end

            # TODO: Write test methods for your cop
            #
            # For example
            def test_does_not_register_offense_for_good_method
              assert_no_offenses(<<~RUBY)
                good_method
              RUBY
            end

            def test_registers_offense_for_bad_method
              assert_offense(<<~RUBY)
                bad_method
                ^^^^^^^^^^ Use `#good_method` instead of `#bad_method`.
              RUBY
            end
          end
        end
      end
    end
  TEST
  puts "[create] #{path}"

  generator.inject_require(root_file_path: "lib/rubocop/cop/sorbet_cops.rb")
  generator.inject_config(config_file_path: "config/default.yml")

  # We don't use Rubocop's changelog automation workflow
  todo_without_changelog_instruction = generator.todo
    .sub(/$\s+4\. Run.*changelog.*for your new cop\.$/m, "")
    .sub(/^  3./, "  3. Run `bundle exec rake generate_cops_documentation` to generate\n     documentation for your new cop.\n  4.")
  puts todo_without_changelog_instruction
end
