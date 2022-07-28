# frozen_string_literal: true

require "spec_helper"

RSpec.describe(RuboCop::Cop::Sorbet::ClassAndModuleChildren, :config) do
  subject(:cop) { described_class.new(config) }
  describe("autocorrect") do
    let(:cop_config) { { 'EnforcedStyle' => 'compact' } }

    it("autocorrects one nested child") do
      source = <<~RUBY
        # typed: true
        # frozen_string_literal: true
        module Foo
          class Bar
          end
        end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          # typed: true
          # frozen_string_literal: true
          class Foo::Bar
          end
      RUBY
    end

    it("autocorrects two nested children") do
      source = <<~RUBY
        # typed: true
        # frozen_string_literal: true
        module Foo
          class Bar
          end

          class Baz
          end
        end
      RUBY
      expect(autocorrect_source(source))
        .to(eq(<<~RUBY))
          # typed: true
          # frozen_string_literal: true
          class Foo::Bar
          end
          class Foo::Baz
          end
      RUBY
    end
  end
end
