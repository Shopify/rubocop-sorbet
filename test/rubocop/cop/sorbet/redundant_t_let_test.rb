# frozen_string_literal: true

require "test_helper"

module RuboCop
  module Cop
    module Sorbet
      class RedundantTLetTest < ::Minitest::Test
        MSG = "Sorbet/RedundantTLet: Unnecessary T.let. The instance variable type is inferred from the signature."
        CONSTRUCTOR_MSG = "Sorbet/RedundantTLet: Unnecessary T.let. " \
          "The constant type is inferred from the constructor."

        def setup
          @cop = RedundantTLet.new
          stub_sorbet_static_version("0.6.13304")
        end

        def test_offense_on_redundant_types
          assert_offense(<<~RUBY)
            sig { params(a: Integer, b: String).void }
            def initialize(a, b)
              @a = T.let(a, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
              @b = T.let(b, String)
                   ^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Integer, b: String).void }
            def initialize(a, b)
              @a = T.let(b, String)
                   ^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Integer).void }
            def initialize(a:)
              @a = T.let(a, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Integer).void }
            def initialize(a = 5)
              @a = T.let(a, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: T.nilable(Integer)).void }
            def initialize(a)
              @a = T.let(a, T.nilable(Integer))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: T::Array[Integer]).void }
            def initialize(a)
              @a = T.let(a, T::Array[Integer])
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Foo[Bar], b: T.any(A, B), c: T.proc.void).void }
            def initialize(a, b, c)
              @a = T.let(a, Foo[Foo])
              @aa = T.let(a, Foo[Bar])
                    ^^^^^^^^^^^^^^^^^^ #{MSG}
              @b = T.let(b, T.any(B, A))
              @bb = T.let(b, T.any(A, B))
                    ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
              @c = T.let(c, T.proc.returns(Integer))
              @cc = T.let(c, T.proc.void)
                    ^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig do
              params(
                proc: T.proc.params(a: String).returns(T.nilable(String)),
              ).void
            end
            def initialize(proc)
              @proc = T.let(proc, T.proc.params(a: String).returns(T.nilable(String)))
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end

            sig { params(a: Integer, b: String, c: String, d: Integer).void }
            def initialize(a, b = "hello", c:, d: 1)
              @a = T.let(a, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
              @b = T.let(b, String)
                   ^^^^^^^^^^^^^^^^ #{MSG}
              @c = T.let(c, String)
                   ^^^^^^^^^^^^^^^^ #{MSG}
              @d = T.let(d, Integer)
                   ^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            sig { params(a: Integer, b: String).void }
            def initialize(a, b)
              @a = a
              @b = b
            end

            sig { params(a: Integer, b: String).void }
            def initialize(a, b)
              @a = b
            end

            sig { params(a: Integer).void }
            def initialize(a:)
              @a = a
            end

            sig { params(a: Integer).void }
            def initialize(a = 5)
              @a = a
            end

            sig { params(a: T.nilable(Integer)).void }
            def initialize(a)
              @a = a
            end

            sig { params(a: T::Array[Integer]).void }
            def initialize(a)
              @a = a
            end

            sig { params(a: Foo[Bar], b: T.any(A, B), c: T.proc.void).void }
            def initialize(a, b, c)
              @a = T.let(a, Foo[Foo])
              @aa = a
              @b = T.let(b, T.any(B, A))
              @bb = b
              @c = T.let(c, T.proc.returns(Integer))
              @cc = c
            end

            sig do
              params(
                proc: T.proc.params(a: String).returns(T.nilable(String)),
              ).void
            end
            def initialize(proc)
              @proc = proc
            end

            sig { params(a: Integer, b: String, c: String, d: Integer).void }
            def initialize(a, b = "hello", c:, d: 1)
              @a = a
              @b = b
              @c = c
              @d = d
            end
          RUBY
        end

        def test_offense_on_args
          assert_offense(<<~RUBY)
            sig { params(args: Integer).void }
            def initialize(*args)
              @args = T.let(args, T::Array[Integer])
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            sig { params(args: Integer).void }
            def initialize(*args)
              @args = args
            end
          RUBY
        end

        def test_offense_on_kwargs
          assert_offense(<<~RUBY)
            sig { params(kwargs: String).void }
            def initialize(**kwargs)
              @kwargs = T.let(kwargs, T::Hash[Symbol, String])
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            sig { params(kwargs: String).void }
            def initialize(**kwargs)
              @kwargs = kwargs
            end
          RUBY
        end

        def test_offense_on_constant_assigned_constructor
          assert_offense(<<~RUBY)
            PATTERN = T.let(Regexp.new("foo"), Regexp)
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
          RUBY

          assert_correction(<<~RUBY)
            PATTERN = Regexp.new("foo")
          RUBY
        end

        def test_offense_on_constant_assigned_frozen_constructor
          assert_offense(<<~RUBY)
            DEFAULT_PATH = T.let(Pathname.new("/usr/local").freeze, Pathname)
                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
          RUBY

          assert_correction(<<~RUBY)
            DEFAULT_PATH = Pathname.new("/usr/local").freeze
          RUBY
        end

        def test_offense_on_constant_assigned_namespaced_constructor
          assert_offense(<<~RUBY)
            MUTEX = T.let(Thread::Mutex.new.freeze, Thread::Mutex)
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
          RUBY

          assert_correction(<<~RUBY)
            MUTEX = Thread::Mutex.new.freeze
          RUBY
        end

        def test_offense_on_constant_assigned_cbase_constructor
          assert_offense(<<~RUBY)
            ROOT = T.let(::Pathname.new("/").freeze, Pathname)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
          RUBY

          assert_correction(<<~RUBY)
            ROOT = ::Pathname.new("/").freeze
          RUBY
        end

        def test_offense_on_constant_assigned_block_constructor
          assert_offense(<<~RUBY)
            CONFIG = T.let(Config.new { |c| c.enabled = true }.freeze, Config)
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
          RUBY

          assert_correction(<<~RUBY)
            CONFIG = Config.new { |c| c.enabled = true }.freeze
          RUBY
        end

        # A numbered-parameter block is a `numblock` node, which Sorbet infers
        # as the instantiated class just like a `{ |x| }` block.
        def test_offense_on_constant_assigned_numbered_block_constructor
          assert_offense(<<~RUBY)
            CONFIG = T.let(Config.new { _1.enabled = true }.freeze, Config)
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
          RUBY

          assert_correction(<<~RUBY)
            CONFIG = Config.new { _1.enabled = true }.freeze
          RUBY
        end

        def test_offense_on_multiline_constant_constructor
          assert_offense(<<~RUBY)
            GITHUB_ERROR = T.let(
                           ^^^^^^ #{CONSTRUCTOR_MSG}
              Regexp.new("some error"),
              Regexp,
            )
          RUBY

          assert_correction(<<~RUBY)
            GITHUB_ERROR = Regexp.new("some error")
          RUBY
        end

        # A heredoc argument's body lives on the lines after the `T.let` marker,
        # so the autocorrection must reattach it instead of dropping it.
        def test_offense_on_constant_constructor_with_heredoc_argument
          assert_offense(<<~RUBY)
            PATH = T.let(
                   ^^^^^^ #{CONSTRUCTOR_MSG}
              Pathname.new(<<~DIR),
                /usr/local
              DIR
              Pathname,
            )
          RUBY

          assert_correction(<<~RUBY)
            PATH = Pathname.new(<<~DIR)
                /usr/local
              DIR
          RUBY
        end

        # The closing `)` sits before the heredoc body, so extending the
        # replaced range past the terminator must not swallow the trailing
        # comment on the marker line.
        def test_offense_on_constant_constructor_with_heredoc_and_trailing_comment
          assert_offense(<<~RUBY)
            PATH = T.let(Pathname.new(<<~DIR), Pathname) # keep me
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
              /usr/local
            DIR
          RUBY

          assert_correction(<<~RUBY)
            PATH = Pathname.new(<<~DIR) # keep me
              /usr/local
            DIR
          RUBY
        end

        # When the `T.let` spans multiple lines a comment can trail the value on
        # the heredoc marker line; extending the replaced range past the body
        # must not swallow it.
        def test_offense_on_constant_constructor_with_heredoc_and_marker_comment
          assert_offense(<<~RUBY)
            PATH = T.let(Pathname.new(<<~DIR), # keep me
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
              /usr/local
            DIR
              Pathname,
            )
          RUBY

          assert_correction(<<~RUBY)
            PATH = Pathname.new(<<~DIR) # keep me
              /usr/local
            DIR
          RUBY
        end

        # An "interior" heredoc is followed by more of the value's own source
        # (here `b: 2` and the closing `)`), so `value_node.source` already
        # contains the heredoc body inline. The correction must not re-append
        # it, which would duplicate the body and corrupt the file.
        def test_offense_on_constant_constructor_with_interior_heredoc
          assert_offense(<<~RUBY)
            PATH = T.let(
                   ^^^^^^ #{CONSTRUCTOR_MSG}
              Foo.new(
                a: <<~DIR,
                  /usr/local
                DIR
                b: 2,
              ),
              Foo,
            )
          RUBY

          assert_correction(<<~RUBY)
            PATH = Foo.new(
                a: <<~DIR,
                  /usr/local
                DIR
                b: 2,
              )
          RUBY
        end

        # Sorbet infers generic constructors as applied types (e.g.
        # `T::Set[T.untyped]`), does not infer through `.tap` or kernel
        # casting methods like `Pathname()`, and only matches when the
        # annotation is exactly the instantiated class.
        def test_no_offense_on_constant_constructors_sorbet_cannot_infer
          assert_no_offenses(<<~RUBY)
            SET = T.let(Set.new.freeze, Set)
            LICENSES = T.let(Set.new(["mit"]).freeze, T::Set[String])
            MISMATCH = T.let(Regexp.new("foo"), Pathname)
            NILABLE = T.let(Pathname.new("/x"), T.nilable(Pathname))
            KERNEL_METHOD = T.let(Pathname("/x").freeze, Pathname)
            TAPPED = T.let(Version.new("NULL").tap { |v| v }.freeze, Version)
          RUBY
        end

        # In typed: strict, Sorbet requires T.let on constants assigned inside
        # a conditional or block, so those must not be flagged.
        def test_no_offense_on_constant_constructor_inside_conditional
          assert_no_offenses(<<~RUBY)
            if enabled?
              DEFAULT_PATH = T.let(Pathname.new("/usr/local").freeze, Pathname)
            end
          RUBY
        end

        # Instance variables are only inferred when assigned directly from a
        # signature parameter, never from a constructor call.
        def test_no_offense_on_ivar_assigned_constructor
          assert_no_offenses(<<~RUBY)
            sig { params(path: String).void }
            def initialize(path)
              @path = T.let(Pathname.new(path), Pathname)
            end
          RUBY
        end

        def test_no_offense_without_t_let
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            def initialize(a)
              @a = a
            end
          RUBY
        end

        def test_no_offense_without_sig
          assert_no_offenses(<<~RUBY)
            def initialize(a)
              @a = T.let(a, Integer)
            end
          RUBY
        end

        def test_no_offense_without_sig_params
          assert_no_offenses(<<~RUBY)
            sig { void }
            def initialize
              @a = T.let(0, Integer)
            end
          RUBY
        end

        def test_no_offense_without_initialize_method
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            def different_method(a)
              @a = T.let(a, Integer)
            end
          RUBY
        end

        def test_no_offense_on_necessary_t_lets
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer) }
            def initialize(a)
              @a = T.let(a, String)
            end

            sig { params(a: Integer).void }
            def initialize(a)
              @a = T.let(a, T.any(Integer, String))
            end

            sig { params(a: Integer).void }
            def initialize(a)
              @a = T.let(a.to_s, String)
            end

            sig { params(a: Integer).void }
            def initialize(a)
              number = a
              @answer = T.let(number, Integer)
            end

            sig { params(a: T.proc.params(x: Integer).returns(String)).void }
            def initialize(a)
              @a = T.let(a, T.proc.params(x: String).returns(String))
            end
          RUBY
        end

        def test_no_offense_inside_block
          assert_no_offenses(<<~RUBY)
            sig { params(items: T::Array[Integer]).void }
            def initialize(items)
              items.each do |item|
                @item = T.let(item, Integer)
              end
            end
          RUBY
        end

        def test_no_offense_with_destructured_parameter
          assert_no_offenses(<<~RUBY)
            def initialize((a, b))
              @a = T.let(a, Integer)
            end
          RUBY
        end

        def test_no_offense_inside_conditional
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            def initialize(a)
              if a > 0
                @a = T.let(a, Integer)
              end
            end
          RUBY
        end

        # Sorbet's initializer rewriter does not process ivar assignments
        # inside a rescue body, so T.let remains required there.
        def test_no_offense_with_rescue_in_body
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            def initialize(a)
              @a = T.let(a, Integer)
            rescue
              @a = T.let(0, Integer)
            end
          RUBY
        end

        # Multiline type annotations in the sig contain whitespace and trailing
        # commas that do not appear in the T.let argument; both sides are
        # normalized before comparison.
        def test_offense_on_multiline_type_in_sig
          assert_offense(<<~RUBY)
            sig do
              params(
                a: T.any(
                  Integer,
                  String,
                ),
              ).void
            end
            def initialize(a)
              @a = T.let(a, T.any(Integer, String))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            sig do
              params(
                a: T.any(
                  Integer,
                  String,
                ),
              ).void
            end
            def initialize(a)
              @a = a
            end
          RUBY
        end

        def test_offense_on_multiline_type_in_t_let
          assert_offense(<<~RUBY)
            sig { params(a: T.any(Integer, String)).void }
            def initialize(a)
              @a = T.let(a, T.any(
                   ^^^^^^^^^^^^^^^ #{MSG}
                Integer,
                String
              ))
            end
          RUBY

          assert_correction(<<~RUBY)
            sig { params(a: T.any(Integer, String)).void }
            def initialize(a)
              @a = a
            end
          RUBY
        end

        # Type comparison normalizes spacing after commas, so a `T.let` type
        # matches the sig type even when their comma spacing differs.
        def test_offense_when_type_comma_spacing_differs_from_sig
          assert_offense(<<~RUBY)
            sig { params(a: T.any(Integer, String)).void }
            def initialize(a)
              @a = T.let(a, T.any(Integer,String))
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            sig { params(a: T.any(Integer, String)).void }
            def initialize(a)
              @a = a
            end
          RUBY
        end

        # Sorbet's initializer rewriter does not process ivar assignments when
        # the def is wrapped by a method modifier, so T.let remains required.
        def test_no_offense_with_method_modifier_wrapping_def
          assert_no_offenses(<<~RUBY)
            sig { params(a: Integer).void }
            private def initialize(a)
              @a = T.let(a, Integer)
            end
          RUBY
        end

        # A constant inside `class << self` or a bare `module` body is still
        # statically scoped, so the constructor offense applies there too.
        def test_offense_on_constant_constructor_in_singleton_class
          assert_offense(<<~RUBY)
            class Foo
              class << self
                DEFAULT = T.let(Pathname.new("/x").freeze, Pathname)
                          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
              end
            end
          RUBY

          assert_correction(<<~RUBY)
            class Foo
              class << self
                DEFAULT = Pathname.new("/x").freeze
              end
            end
          RUBY
        end

        def test_offense_on_constant_constructor_in_module
          assert_offense(<<~RUBY)
            module Foo
              DEFAULT = T.let(Pathname.new("/x").freeze, Pathname)
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
            end
          RUBY

          assert_correction(<<~RUBY)
            module Foo
              DEFAULT = Pathname.new("/x").freeze
            end
          RUBY
        end

        # The generic-class exclusion covers every entry in GENERIC_CLASSES,
        # not just Set: their constructors infer as applied types.
        def test_no_offense_on_other_generic_class_constructors
          assert_no_offenses(<<~RUBY)
            HASH = T.let(Hash.new(0).freeze, Hash)
            ARRAY = T.let(Array.new(3).freeze, Array)
            RANGE = T.let(Range.new(1, 2).freeze, Range)
            ENUM = T.let(Enumerator.new { |y| y << 1 }.freeze, Enumerator)
            KLASS = T.let(Class.new.freeze, Class)
            MOD = T.let(Module.new.freeze, Module)
          RUBY
        end

        # `::T.let` (fully-qualified) is handled for the constructor path too.
        def test_offense_on_constant_constructor_with_cbase_t_let
          assert_offense(<<~RUBY)
            ROOT = ::T.let(Pathname.new("/").freeze, Pathname)
                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{CONSTRUCTOR_MSG}
          RUBY

          assert_correction(<<~RUBY)
            ROOT = Pathname.new("/").freeze
          RUBY
        end

        # The constructor path relies on freeze-transparent inference added in
        # Sorbet 0.6.13304, so it disables itself on older Sorbet (and when
        # sorbet-static is absent from the lockfile). The signature-based ivar
        # path is unaffected.
        def test_no_offense_on_constructor_below_minimum_sorbet_version
          stub_sorbet_static_version("0.6.13303")
          assert_no_offenses(<<~RUBY)
            DEFAULT_PATH = T.let(Pathname.new("/usr/local").freeze, Pathname)
          RUBY
        end

        def test_no_offense_on_constructor_without_sorbet_static
          stub_sorbet_static_version(nil)
          assert_no_offenses(<<~RUBY)
            DEFAULT_PATH = T.let(Pathname.new("/usr/local").freeze, Pathname)
          RUBY
        end

        private

        def stub_sorbet_static_version(version)
          specs = version ? [Gem::Specification.new("sorbet-static", version)] : []
          ::Bundler.stubs(:locked_gems).returns(Struct.new(:specs).new(specs))
        end
      end
    end
  end
end
