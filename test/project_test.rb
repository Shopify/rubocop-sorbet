# frozen_string_literal: true

require "test_helper"
require "pathname"

class ProjectTest < Minitest::Test
  RBI_ONLY_COPS = [
    "Sorbet/ValidGemVersionAnnotations",
  ]

  def test_no_rogue_rubocop_comments
    root_directory = Pathname.new(File.expand_path("..", __dir__))

    Dir.glob(File.join(root_directory, "manual/**/*.md")).each do |path|
      relative_path = Pathname.new(path).relative_path_from(root_directory)
      contents = File.read(path)

      refute_match(
        /rubocop:(?:todo|disable)/,
        contents,
        "File #{relative_path} contains rogue rubocop comments",
      )
    end
  end

  def test_has_configuration_for_all_cops
    assert_equal(code_cop_names.sort, cops_on(config))
  end

  def cop_names
    @cop_names ||= RuboCop::Cop::Registry
      .global
      .select { |cop| cop.cop_name.start_with?("Sorbet/") }
      .map(&:cop_name)
  end

  def code_cop_names
    @code_cop_names ||= cop_names - RBI_ONLY_COPS
  end

  def config
    @config ||= RuboCop::ConfigLoader.load_file("config/default.yml")
  end

  def cops_on(config)
    config.keys.reject { |key| key == "inherit_mode" }
  end
end
