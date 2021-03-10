# frozen_string_literal: true

require 'spec_helper'

RSpec.describe(RuboCop::Cop::Sorbet::ForbidExtendTSigInShims, :config) do
  subject(:cop) { described_class.new(config) }

  describe('offences') do
    it 'adds an offence when a targeted class or module extends T::Sig' do
      expect_offense(<<~RBI)
        module MyModule
          extend T::Sig
          ^^^^^^^^^^^^^ Extending T::Sig in a shim is unnecessary

          sig { returns(String) }
          def foo; end
        end
      RBI
    end
  end

  describe('no offences') do
    it 'does not add an offence to uses of extend that are not T::Sig' do
      expect_no_offenses(<<~RBI)
        module MyModule
          extend ActiverSupport::Concern

          def foo; end
        end
      RBI
    end
  end

  describe('autocorrect') do
    it 'autocorrects usages of extend T::Sig by removing them' do
      source = <<~RBI
        module MyModule
          extend T::Sig
          extend ActiveSupport::Concern

          sig { returns(String) }
          def foo; end
        end
      RBI
      expect(autocorrect_source(source))
        .to(eq(<<~RBI))
          module MyModule
            extend ActiveSupport::Concern

            sig { returns(String) }
            def foo; end
          end
        RBI
    end
  end
end
