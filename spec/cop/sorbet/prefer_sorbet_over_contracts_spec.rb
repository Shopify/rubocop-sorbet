# frozen_string_literal: true

require "spec_helper"

require_relative "../../../lib/rubocop/cop/sorbet/prefer_sorbet_over_contracts"

RSpec.describe(RuboCop::Cop::Sorbet::PreferSorbetOverContracts, :config) do
  subject(:cop) { RuboCop::Cop::Sorbet::PreferSorbetOverContracts.new }

  context "Fixes Contracts" do
    describe "Auto-correct works for constants" do
      let(:source) do
        <<~RUBY
          class Example
            include Contracts::Core
            include Contracts::Builtin

            def self.dummy
              'will'
            end

            Contract Integer => AirProcurement::AllotmentEntity
            def self.number_is_even(num)
              return false
            end

            Contract A::B::C => D::E::F
            def self.three_args(abc)
              return false
            end

            Contract A::B::C::D => D::E::F::G
            def self.four_args(abcd)
              return false
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            include Contracts::Core
            include Contracts::Builtin

            def self.dummy
              'will'
            end

            sig { params(num: Integer).returns(AirProcurement::AllotmentEntity) }
            def self.number_is_even(num)
              return false
            end

            sig { params(abc: A::B::C).returns(D::E::F) }
            def self.three_args(abc)
              return false
            end

            sig { params(abcd: A::B::C::D).returns(D::E::F::G) }
            def self.four_args(abcd)
              return false
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Auto-corrects none" do
      let(:source) do
        <<~RUBY
          class Example < ExampleBase
            Contract Or[Time, DateTime] => Or[Time, DateTime]
            def self.cool_thing(time)
              return "will"
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example < ExampleBase
            extend T::Sig
            sig { params(time: T.any(Time, DateTime)).returns(T.any(Time, DateTime)) }
            def self.cool_thing(time)
              return "will"
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Auto-corrects none" do
      let(:source) do
        <<~RUBY
          class Example
            Contract None => String
            def self.cool_thing
              return "will"
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { returns(String) }
            def self.cool_thing
              return "will"
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Auto-corrects void" do
      context 'there is a param' do
        context 'param is string' do
          let(:source) do
            <<~RUBY
              class Example
                Contract String => nil
                def self.cool_thing(str)
                end
              end
            RUBY
          end
          let(:fixed_source) do
            <<~RUBY
              class Example
                extend T::Sig
                sig { params(str: String).void }
                def self.cool_thing(str)
                end
              end
            RUBY
          end

          it "autocorrects the offense" do
            new_source = autocorrect_source(source)
            expect(new_source).to(eq(fixed_source))
          end
        end
      end

      context 'there is no param' do
        let(:source) do
          <<~RUBY
            class Example
              Contract None => nil
              def self.cool_thing
              end
            end
          RUBY
        end
        let(:fixed_source) do
          <<~RUBY
            class Example
              extend T::Sig
              sig { void }
              def self.cool_thing
              end
            end
          RUBY
        end

        it "autocorrects the offense" do
          new_source = autocorrect_source(source)
          expect(new_source).to(eq(fixed_source))
        end
      end
    end

    describe "Auto-corrects self" do
      let(:source) do
        <<~RUBY
          class Example
            Contract String => self
            def self.cool_thing(str)
              self
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { params(str: String).returns(T.self_type) }
            def self.cool_thing(str)
              self
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrect works for two constants" do
      let(:source) do
        <<~RUBY
          class Example
            Contract Integer, Boolean => String
            def self.cool_thing(number, bool)
              return false
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { params(number: Integer, bool: T::Boolean).returns(String) }
            def self.cool_thing(number, bool)
              return false
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrect works for private class methods" do
      let(:source) do
        <<~RUBY
          class Example
            Contract OperationalRoute::Graph, Integer, User => Result
            private_class_method def self.find_or_create_warehouse_node(graph, warehouse_id, updated_by)
              return false
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { params(graph: OperationalRoute::Graph, warehouse_id: Integer, updated_by: User).returns(Result) }
            private_class_method def self.find_or_create_warehouse_node(graph, warehouse_id, updated_by)
              return false
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrect works for five constants" do
      let(:source) do
        <<~RUBY
          class Example
            Contract Integer, Boolean, String, Date, Integer  => String
            def self.cool_thing(number, bool, string, date, integer)
              return false
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { params(number: Integer, bool: T::Boolean, string: String, date: Date, integer: Integer).returns(String) }
            def self.cool_thing(number, bool, string, date, integer)
              return false
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrect works for maybe and array" do
      let(:source) do
        <<~RUBY
          class Example
            Contract Maybe[Integer], Maybe[Boolean] => ArrayOf[String]
            def self.cool_thing(integers, booleans)
              return ["cool", "will"]
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { params(integers: T.nilable(Integer), booleans: T.nilable(T::Boolean)).returns(T::Array[String]) }
            def self.cool_thing(integers, booleans)
              return ["cool", "will"]
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrect works for nested sends" do
      let(:source) do
        <<~RUBY
          class Example
            Contract Maybe[Air::Man], Maybe[ArrayOf[String]] => Maybe[ArrayOf[Red::Sox]]
            def cool_thing(jordan, strings)
              return ["cool", "will"]
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { params(jordan: T.nilable(Air::Man), strings: T.nilable(T::Array[String])).returns(T.nilable(T::Array[Red::Sox])) }
            def cool_thing(jordan, strings)
              return ["cool", "will"]
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrect works for hashes" do
      let(:source) do
        <<~RUBY
          class Example
            Contract HashOf[String, Any], HashOf[String, Chris::Sale] => Maybe[HashOf[String, Red::Sox]]
            def self.cool_thing(jordan, strings)
              return ["cool", "will"]
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { params(jordan: T::Hash[String, T.untyped], strings: T::Hash[String, Chris::Sale]).returns(T.nilable(T::Hash[String, Red::Sox])) }
            def self.cool_thing(jordan, strings)
              return ["cool", "will"]
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Fixes KeywordArgs" do
      let(:src) do
        <<~RUBY
          class Example
            Contract Contracts::KeywordArgs[pats: Maybe[Tom::Brady], sox: Maybe[Big::Papi]] => ArrayOf[Gronk]
            def self.cool_thing(pats: nil, sox: nil)
              return ["cool", "will"]
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { params(pats: T.nilable(Tom::Brady), sox: T.nilable(Big::Papi)).returns(T::Array[Gronk]) }
            def self.cool_thing(pats: nil, sox: nil)
              return ["cool", "will"]
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Fixes tuple" do
      let(:src) do
        <<~RUBY
          class Example
            Contract [Maybe[Tom::Brady], Maybe[Big::Papi]] => ArrayOf[Gronk]
            def self.cool_thing(args)
              return ["cool", "will"]
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            extend T::Sig
            sig { params(args: [T.nilable(Tom::Brady), T.nilable(Big::Papi)]).returns(T::Array[Gronk]) }
            def self.cool_thing(args)
              return ["cool", "will"]
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Leaves Enums alone" do
      let(:source) do
        <<~RUBY
          class Example
            Contract ArrayOf[Enum[*PERMITTED_KEYS]] => Maybe[String]
            def self.cool_thing(key)
              return "coolwill"
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class Example
            Contract ArrayOf[Enum[*PERMITTED_KEYS]] => Maybe[String]
            def self.cool_thing(key)
              return "coolwill"
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrects full path ArrayOf" do
      let(:src) do
        <<~RUBY
          class FullPathExample
            def self.buffer
              nil
            end

            Contract String => Contracts::ArrayOf[ContainerUse]
            def self.cool_thing(key)
              return "coolwill"
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class FullPathExample
            extend T::Sig
            def self.buffer
              nil
            end

            sig { params(key: String).returns(T::Array[ContainerUse]) }
            def self.cool_thing(key)
              return "coolwill"
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrects with param default values" do
      let(:src) do
        <<~RUBY
          class FullPathExample
            Contract String, Maybe[Hash] => Bool
            def self.cool_thing(key = "cool", hash = nil)
              return true
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class FullPathExample
            extend T::Sig
            sig { params(key: String, hash: T.nilable(T::Hash[T.untyped, T.untyped])).returns(T::Boolean) }
            def self.cool_thing(key = "cool", hash = nil)
              return true
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Auto-correct works for constants" do
      let(:source) do
        <<~RUBY
          module Outer
            class Example
              include Contracts::Core
              include Contracts::Builtin

              Contract Integer => ::AirProcurement::AllotmentEntity
              def self.number_is_even(num)
                return false
              end
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          module Outer
            class Example
              extend T::Sig
              include Contracts::Core
              include Contracts::Builtin

              sig { params(num: Integer).returns(AirProcurement::AllotmentEntity) }
              def self.number_is_even(num)
                return false
              end
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(source)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Autocorrects with mixed param default values" do
      let(:src) do
        <<~RUBY
          class FullPathExample
            Contract Maybe[CompanyEntity], Maybe[CompanyEntity], Integer => ArrayOf[ShippingInstruction]
            def self.historic_shipper_shipping_instructions(shipper, consignee, number_of_record: DEFAULT_NUMBER_HISTORIC_RECORD)
              return []
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class FullPathExample
            extend T::Sig
            sig { params(shipper: T.nilable(CompanyEntity), consignee: T.nilable(CompanyEntity), number_of_record: Integer).returns(T::Array[ShippingInstruction]) }
            def self.historic_shipper_shipping_instructions(shipper, consignee, number_of_record: DEFAULT_NUMBER_HISTORIC_RECORD)
              return []
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Does not change literal values" do
      let(:src) do
        <<~RUBY
          class FullPathExample
            def self.buffer
              nil
            end

            Contract Or["scheduled", "actual"] => Any
            def self.cool_thing(key)
              return true
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class FullPathExample
            def self.buffer
              nil
            end

            Contract Or["scheduled", "actual"] => Any
            def self.cool_thing(key)
              return true
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Handles &block param" do
      let(:src) do
        <<~RUBY
          class FullPathExample
            Contract Maybe[String], Proc => Any
            def with_frontend_context(event_source, &block)
              return true
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class FullPathExample
            extend T::Sig
            sig { params(event_source: T.nilable(String), block: T.proc.void).returns(T.untyped) }
            def with_frontend_context(event_source, &block)
              return true
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Handles => syntax" do
      let(:src) do
        <<~RUBY
          class FullPathExample
            Contract None => HashOf[String => Integer]
            def with_frontend_context
              return {}
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class FullPathExample
            extend T::Sig
            sig { returns(T::Hash[String, Integer]) }
            def with_frontend_context
              return {}
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Handles shapes" do
      let(:src) do
        <<~RUBY
          class FullPathExample
            Contract ArrayOf[
                 {
                   "place_id" => Or[Num, String],
                   "tags_list" => ArrayOf[String],
                 }
             ],
            String => Maybe[Num]
            def with_frontend_context(arr, num)
              return 1
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class FullPathExample
            extend T::Sig
            sig { params(arr: T::Array[{place_id: T.any(Numeric, String), tags_list: T::Array[String]}], num: String).returns(T.nilable(Numeric)) }
            def with_frontend_context(arr, num)
              return 1
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Handles Contract::" do
      let(:src) do
        <<~RUBY
          class FullPathExample
            Contract Contracts::Bool, Contracts::Maybe[Contracts::Num] => Contracts::Any
            def with_frontend_context(bool, num)
              return true
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class FullPathExample
            extend T::Sig
            sig { params(bool: T::Boolean, num: T.nilable(Numeric)).returns(T.untyped) }
            def with_frontend_context(bool, num)
              return true
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    describe "Handles Contract::" do
      let(:src) do
        <<~RUBY
          class FullPathExample
            Contract String, {from_warehouse: Contracts::Bool, cool: String} => {result: {errors: Contracts::ArrayOf[String]}}
            def self.generate_deliveries_report(email, from_warehouse:)
              return true
            end
          end
        RUBY
      end
      let(:fixed_source) do
        <<~RUBY
          class FullPathExample
            extend T::Sig
            sig { params(email: String, from_warehouse: {from_warehouse: T::Boolean, cool: String}).returns({result: {errors: T::Array[String]}}) }
            def self.generate_deliveries_report(email, from_warehouse:)
              return true
            end
          end
        RUBY
      end

      it "autocorrects the offense" do
        new_source = autocorrect_source(src)
        expect(new_source).to(eq(fixed_source))
      end
    end

    context "when the contract has incorrect arity" do
      describe "for a zero argument function" do
        let(:src) do
          <<~RUBY
            class ZeroArgFunctionWithIncorrectButNotFailingContract
              Contract Hash => String
              def hello
                return "Hello World"
              end
            end
          RUBY
        end
        let(:fixed_source) do
          <<~RUBY
            class ZeroArgFunctionWithIncorrectButNotFailingContract
              extend T::Sig
              sig { returns(String) }
              def hello
                return "Hello World"
              end
            end
          RUBY
        end

        it "autocorrects the offense" do
          new_source = autocorrect_source(src)
          expect(new_source).to(eq(fixed_source))
        end
      end

      describe "for a function with arguments" do
        let(:src) do
          <<~RUBY
            class SeriouslyWhyDoesThisContractNotFail
              Contract Integer, Integer => Integer
              def plusOne(a)
                return a+1
              end
            end
          RUBY
        end
        let(:fixed_source) do
          <<~RUBY
            class SeriouslyWhyDoesThisContractNotFail
              extend T::Sig
              sig { params(a: Integer).returns(Integer) }
              def plusOne(a)
                return a+1
              end
            end
          RUBY
        end

        it "autocorrects the offense" do
          new_source = autocorrect_source(src)
          expect(new_source).to(eq(fixed_source))
        end
      end
    end

    describe "Autocorrect works for shorthand no param list" do
      context 'return param is a boolean' do
        let(:source) do
          <<~RUBY
            class ClassWithShorthandNoParams
              Contract Bool
              def returns_bool
                return false
              end
            end
          RUBY
        end
        let(:fixed_source) do
          <<~RUBY
            class ClassWithShorthandNoParams
              extend T::Sig
              sig { returns(T::Boolean) }
              def returns_bool
                return false
              end
            end
          RUBY
        end

        it "autocorrects the offense" do
          new_source = autocorrect_source(source)
          expect(new_source).to(eq(fixed_source))
        end

      end

      context 'return param is a hash' do
        let(:source) do
          <<~RUBY
            class ClassWithShorthandNoParams
              Contract HashOf[Symbol => Symbol]
              def returns_bool
                return false
              end
            end
          RUBY
        end
        let(:fixed_source) do
          <<~RUBY
            class ClassWithShorthandNoParams
              extend T::Sig
              sig { returns(T::Hash[Symbol, Symbol]) }
              def returns_bool
                return false
              end
            end
          RUBY
        end

        it "autocorrects the offense" do
          new_source = autocorrect_source(source)
          expect(new_source).to(eq(fixed_source))
        end
      end

      context 'return param is nil' do
        let(:source) do
          <<~RUBY
            class ClassWithShorthandNoParams
              Contract nil
              def returns_bool
                return false
              end
            end
          RUBY
        end
        let(:fixed_source) do
          <<~RUBY
            class ClassWithShorthandNoParams
              extend T::Sig
              sig { void }
              def returns_bool
                return false
              end
            end
          RUBY
        end

        it "autocorrects the offense" do
          new_source = autocorrect_source(source)
          expect(new_source).to(eq(fixed_source))
        end
      end

      context 'return param is any' do
        let(:source) do
          <<~RUBY
            class ClassWithShorthandNoParams
              Contract Any
              def returns_bool
                return false
              end
            end
          RUBY
        end
        let(:fixed_source) do
          <<~RUBY
            class ClassWithShorthandNoParams
              extend T::Sig
              sig { returns(T.untyped) }
              def returns_bool
                return false
              end
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
end