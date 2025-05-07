# frozen_string_literal: true

require "test_helper"
require "pathname"

class DocumentationTest < Minitest::Test
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
end
