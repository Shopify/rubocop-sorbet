# frozen_string_literal: true

require "spec_helper"
require "pathname"

RSpec.describe("generated documentation") do
  root_directory = Pathname.new(File.expand_path("..", __dir__))

  Dir.glob(File.join(root_directory, "manual/**/*.md")).each do |path|
    context(Pathname.new(path).relative_path_from(root_directory)) do
      it "does not contain any rogue `rubocop:___` comments" do
        contents = File.read(path)
        expect(contents).not_to(match(/rubocop:(?:todo|disable)/))
      end
    end
  end
end
