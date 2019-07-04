require "test_helper"

class Rubocop::SorbetTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Rubocop::Sorbet::VERSION
  end
end
