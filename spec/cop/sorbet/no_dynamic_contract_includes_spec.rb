# frozen_string_literal: true

require "spec_helper"

require_relative '../../../lib/rubocop/cop/sorbet/no_dynamic_contract_includes'

RSpec.describe(RuboCop::Cop::Sorbet::NoDynamicContractIncludes) do
  subject(:cop) { RuboCop::Cop::Sorbet::NoDynamicContractIncludes.new }

  context "Fixes Dry::Types.module imports" do
    describe "Detects include" do
      let(:source) do
        <<~RUBY
          class ExampleRecord < Dry::Struct
            include Dry::Types.module
            ^^^^^^^^^^^^^^^^^^^^^^^^^ Sorbet disallows dynamic includes. Do not include Dry::Types.module directly; use direct path instead.
            class Unit < Dry::Struct
              attribute :name, Strict::Symbol
                               ^^^^^^^^^^^^^^ Sorbet disallows dynamic includes. Use full Dry::Types path instead.
              attribute :power, Strict::Int
                                ^^^^^^^^^^^ Sorbet disallows dynamic includes. Use full Dry::Types path instead.
            end
          end
        RUBY
      end

      it "adds offenses" do
        expect_offense(source)
      end
    end

    describe "Autocorrect works for objects" do
      let(:source) do
        <<~RUBY
          class ExampleRecord
            def index_schema
              {
                booking_mode: Types::Strict::String,
                on_date: Types::DateTime,
                page: Types::Coercible::Int,
                pages: Types::Array,
                hash: Types::Hash.schema,
              }
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class ExampleRecord
            def index_schema
              {
                booking_mode: Dry::Types["strict.string"],
                on_date: Dry::Types["date_time"],
                page: Dry::Types["coercible.int"],
                pages: Dry::Types["array"],
                hash: Dry::Types["hash"].schema,
              }
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrect works for attribute" do
      let(:source) do
        <<~RUBY
          class ExampleRecord < Dry::Struct
            include Dry::Types.module
            class Unit < Dry::Struct
              attribute :instance, Instance(CoolClass)
              attribute :name, Strict::Symbol
              attribute :power, Strict::Int
              attribute :sweet, Dry::Types["strict.int"]
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class ExampleRecord < Dry::Struct
            include Dry::Types.module
            class Unit < Dry::Struct
              attribute :instance, Dry::Types::Definition.new(CoolClass).constrained(type: CoolClass)
              attribute :name, Dry::Types["strict.symbol"]
              attribute :power, Dry::Types["strict.int"]
              attribute :sweet, Dry::Types["strict.int"]
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrect works for normal" do
      let(:source) do
        <<~RUBY
          class ExampleRecord < Dry::Struct
            SampleEnum = Strict::Symbol.enum(
              :first,
              :second,
              :third
            )
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class ExampleRecord < Dry::Struct
            SampleEnum = Dry::Types["strict.symbol"].enum(
              :first,
              :second,
              :third
            )
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end
  end
end
