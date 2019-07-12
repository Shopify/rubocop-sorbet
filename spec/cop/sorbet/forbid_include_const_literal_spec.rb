# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../lib/rubocop/cop/sorbet/forbid_include_const_literal'

RSpec.describe(RuboCop::Cop::Sorbet::ForbidIncludeConstLiteral, :config) do
  subject(:cop) { described_class.new(config) }

  it 'adds offense when an include is a send node' do
    expect_offense(<<~RUBY)
      class MyClass
        include Rails.application.routes.url_helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it 'adds offense when an include is a qualified send node' do
    expect_offense(<<~RUBY)
      class MyClass
        mod = ThatMod
        include mod
        ^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it 'adds offense when an include is a qualified send node' do
    expect_offense(<<~RUBY)
      class MyClass
        include Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it 'adds offense when a prepend is a send node' do
    expect_offense(<<~RUBY)
      class MyClass
        prepend Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it 'adds offense when an extend is a send node' do
    expect_offense(<<~RUBY)
      class MyClass
        extend Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it 'adds offense when a module includes with a send node' do
    expect_offense(<<~RUBY)
      module MyModule
        extend Polaris::Engine.helpers
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
      end
    RUBY
  end

  it 'adds offense when a singleton class includes with a send node' do
    expect_offense(<<~RUBY)
      module FilterHelper
        class << self
          include ActionView::Helpers::TagHelper
          include Rails.application.routes.url_helpers
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Includes must only contain constant literals
        end
      end
    RUBY
  end

  it 'does not add offense when there is no include' do
    expect_no_offenses(<<~RUBY)
      class MyClass
      end
    RUBY
  end

  it 'does not add offense when the include is a qualified name' do
    expect_no_offenses(<<~RUBY)
      class MyClass
        include MyModule::MyParent
      end
    RUBY
  end

  it 'does not add offense when the include is a constant literal' do
    expect_no_offenses(<<~RUBY)
      MyInclude = Rails.application.routes.url_helpers
      class MyClass
        include MyInclude
      end
    RUBY
  end

  it 'does not add offense when an anonymous class includes with a send node' do
    expect_no_offenses(<<~RUBY)
      UrlHelpers =
        Class.new do
          include(Rails.application.routes.url_helpers)
        end.new
    RUBY
  end

  it 'does not add offense when include is called inside a method' do
    expect_no_offenses(<<~RUBY)
      def foo
        m = Module.new
        prepend(m)
      end
    RUBY
  end

  it 'does not add offense when a module extend self' do
    expect_no_offenses(<<~RUBY)
      module Foo
        extend self
      end
    RUBY
  end

  it 'does not add offense when a class extend self' do
    expect_no_offenses(<<~RUBY)
      class Foo
        extend self
      end
    RUBY
  end

  context 'autocorrect' do
    it 'autocorrects includes of sends with an intermediate variable' do
      source = <<~RUBY
        class MyClass
          include Rails.application.routes.url_helpers
        end
      RUBY

      corrected_source = <<~RUBY
        class MyClass
          MyClassInclude = Rails.application.routes.url_helpers
          include MyClassInclude
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects includes of qualified sends with an intermediate variable' do
      source = <<~RUBY
        class MyClass
          include Polaris::Engine.helpers
        end
      RUBY

      corrected_source = <<~RUBY
        class MyClass
          MyClassInclude = Polaris::Engine.helpers
          include MyClassInclude
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects includes in modules' do
      source = <<~RUBY
        module MyModule
          include Polaris::Engine.helpers
        end
      RUBY

      corrected_source = <<~RUBY
        module MyModule
          MyModuleInclude = Polaris::Engine.helpers
          include MyModuleInclude
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects multiple includes' do
      source = <<~RUBY
        class MyClass
          include BBRails.application.routes.url_helpers
          include BBPolaris::Engine.helpers
        end
      RUBY

      corrected_source = <<~RUBY
        class MyClass
          MyClassInclude = BBRails.application.routes.url_helpers
          include MyClassInclude
          MyClassInclude2 = BBPolaris::Engine.helpers
          include MyClassInclude2
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects and preserve not offending includes' do
      source = <<~RUBY
        class NavItemManager
          include SmartProperties
          include Rails.application.routes.url_helpers
          include Admin::NavHelper
        end
      RUBY

      corrected_source = <<~RUBY
        class NavItemManager
          include SmartProperties
          NavItemManagerInclude = Rails.application.routes.url_helpers
          include NavItemManagerInclude
          include Admin::NavHelper
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects and preserves indent' do
      source = <<~RUBY
        module Foo
          class MyClass
            include Rails.application.routes.url_helpers
          end
        end
      RUBY

      corrected_source = <<~RUBY
        module Foo
          class MyClass
            MyClassInclude = Rails.application.routes.url_helpers
            include MyClassInclude
          end
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end

    it 'autocorrects and preserves qualified names' do
      source = <<~RUBY
        module Admin::FilterFormHelper
          include Polaris::Engine.helpers
        end
      RUBY

      corrected_source = <<~RUBY
        module Admin::FilterFormHelper
          FilterFormHelperInclude = Polaris::Engine.helpers
          include FilterFormHelperInclude
        end
      RUBY

      expect(autocorrect_source(source)).to(eq(corrected_source))
    end
  end
end
