# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module RuboCop
  class RBSConfigTest < ::Minitest::Test
    def setup
      @config = ConfigLoader.configuration_from_file(File.expand_path("../../config/rbs.yml", __dir__))
    end

    def test_accepts_rbs_signatures_aliases_helpers_and_assertions
      assert_empty(offenses(<<~RUBY))
        # typed: true
        #: type string_or_integer = String | Integer

        # @abstract
        class Example
          #: String
          attr_reader :name

          #: (
          #|   string_or_integer
          #| ) -> void
          def process(value)
            result = value #: String | Integer
            result #: as String
            result #: as !nil
            result #: as untyped
            #: self as Example
            raise #: absurd(value)
          end
        end
      RUBY
    end

    def test_rejects_sorbet_signatures_aliases_helpers_and_assertions
      names = offenses(<<~RUBY).map(&:cop_name).uniq.sort
        # typed: true
        class Example
          extend T::Sig
          extend T::Helpers
          Alias = T.type_alias { String }

          sig { void }
          def process
            T.let(value, String)
            T.cast(value, String)
            T.must(value)
            T.unsafe(value)
            T.absurd(value)
            T.bind(self, Example)
            T.untyped
          end

          T::Sig.sig { void }
          def with_runtime; end

          T::Sig::WithoutRuntime.sig { void }
          def without_runtime; end
        end
      RUBY

      assert_equal(
        [
          "Sorbet/EnforceSignatures",
          "Sorbet/ForbidSig",
          "Sorbet/ForbidSigWithRuntime",
          "Sorbet/ForbidSigWithoutRuntime",
          "Sorbet/ForbidTAbsurd",
          "Sorbet/ForbidTBind",
          "Sorbet/ForbidTCast",
          "Sorbet/ForbidTHelpers",
          "Sorbet/ForbidTLet",
          "Sorbet/ForbidTMust",
          "Sorbet/ForbidTSig",
          "Sorbet/ForbidTTypeAlias",
          "Sorbet/ForbidTUnsafe",
          "Sorbet/ForbidTUntyped",
        ],
        names,
      )
    end

    def test_requires_rbs_signatures
      result = offenses("# typed: true\ndef process; end\n")

      assert_equal(["Sorbet/EnforceSignatures"], result.map(&:cop_name))
      assert_includes(result.first.message, "Each method is required to have an RBS signature.")
    end

    def test_keeps_enum_and_struct_available
      assert_empty(offenses(<<~RUBY))
        # typed: true
        class Status < T::Enum
          enums do
            Active = new
            Inactive = new
          end
        end

        class Record < T::Struct
          const :name, String
        end
      RUBY
    end

    def test_autocorrects_missing_signatures_to_rbs
      result, corrected = investigate("# typed: true\ndef process; end\n", autocorrect: true)

      assert_equal(["Sorbet/EnforceSignatures"], result.map(&:cop_name))
      assert_equal("# typed: true\n#: () -> untyped\ndef process; end\n", corrected)
      assert_empty(offenses(corrected))
    end

    def test_reports_unaliased_types_without_generating_a_forbidden_alias
      source = "# typed: true\nValue = T.any(String, Integer)\n"
      result, corrected = investigate(source, autocorrect: true)

      assert_equal(["Sorbet/BindingConstantWithoutTypeAlias"], result.map(&:cop_name))
      assert_equal(source, corrected)
    end

    def test_reports_without_runtime_sigs_without_replacing_them_with_forbidden_sigs
      source = <<~RUBY
        # typed: true
        T::Sig::WithoutRuntime.sig { void } # rubocop:disable Sorbet/EnforceSignatures
        def process; end
      RUBY
      result, corrected = investigate(source, autocorrect: true)

      assert_includes(result.map(&:cop_name), "Sorbet/ForbidSigWithoutRuntime")
      assert_equal(source, corrected)
    end

    def test_reports_obsolete_memoization_without_removing_a_local_exception
      specs = [Gem::Specification.new("sorbet-static", "0.5.10210")]
      ::Bundler.stubs(:locked_gems).returns(Struct.new(:specs).new(specs))
      source = <<~RUBY
        # typed: strict
        #: -> Object
        def value
          @value = T.let(@value, T.nilable(Object)) # rubocop:disable Sorbet/ForbidTLet
          @value ||= Object.new
        end
      RUBY
      result, corrected = investigate(source, autocorrect: true)

      assert_equal(["Sorbet/ObsoleteStrictMemoization"], result.map(&:cop_name))
      assert_equal(source, corrected)
    end

    def test_checks_redundant_t_let_when_rbs_bans_are_suppressed
      result = offenses(<<~RUBY)
        # typed: true
        class Example
          sig { params(value: Integer).void } # rubocop:disable Sorbet/ForbidSig, Sorbet/EnforceSignatures
          def initialize(value)
            @value = T.let(value, Integer) # rubocop:disable Sorbet/ForbidTLet
          end
        end
      RUBY

      assert_equal(["Sorbet/RedundantTLet"], result.map(&:cop_name))
    end

    def test_can_apply_rbs_policy_to_a_migrated_directory
      Dir.mktmpdir do |directory|
        File.write(File.join(directory, ".rubocop.yml"), <<~YAML)
          plugins:
            - rubocop-sorbet
        YAML
        app = File.join(directory, "app")
        Dir.mkdir(app)
        path = File.join(app, ".rubocop.yml")
        File.write(path, <<~YAML)
          inherit_from: ../.rubocop.yml
          inherit_gem:
            rubocop-sorbet: config/rbs.yml
        YAML
        @config = ConfigStore.new.for_file(File.join(app, "example.rb"))

        assert_empty(offenses("# typed: true\n#: -> void\ndef process; end\n"))
        assert_equal(["Sorbet/ForbidTMust"], offenses("# typed: true\nT.must(value)\n").map(&:cop_name))

        @config = ConfigStore.new.for_file(File.join(directory, "example.rb"))
        assert_empty(offenses("# typed: true\nsig { void }\ndef legacy; T.must(value); end\n"))
      end
    end

    def test_combines_with_rbi_preset_and_allows_project_overrides
      Dir.mktmpdir do |directory|
        path = File.join(directory, ".rubocop.yml")
        File.write(path, <<~YAML)
          inherit_gem:
            rubocop-sorbet:
              - config/rbi.yml
              - config/rbs.yml

          Sorbet/EnforceSignatures:
            Enabled: false

          Sorbet/ForbidTMust:
            Enabled: false
        YAML
        @config = ConfigLoader.configuration_from_file(path)

        assert_empty(offenses("# typed: true\ndef process; T.must(value); end\n"))
        assert_equal(["Sorbet/ForbidTCast"], offenses("# typed: true\nT.cast(value, String)\n").map(&:cop_name))
      end
    end

    private

    def offenses(source)
      investigate(source).first
    end

    def investigate(source, autocorrect: false)
      cops = Cop::Registry.all.select do |cop|
        cop.department == :Sorbet || cop == Cop::Layout::LeadingCommentSpace
      end
      options = { raise_error: true, autocorrect: autocorrect, stdin: source }
      team = Cop::Team.mobilize(cops, @config, options)
      processed_source = ProcessedSource.new(source, RUBY_VERSION.to_f, File.join(Dir.pwd, "example.rb"))
      processed_source.config = @config
      processed_source.registry = Cop::Registry.new(cops)

      result = team.investigate(processed_source).offenses.reject(&:disabled?)
      [result, options[:stdin]]
    end
  end
end
