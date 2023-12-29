# Sorbet

## Sorbet/AllowIncompatibleOverride

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.2.0 | -

Disallows using `.override(allow_incompatible: true)`.
Using `allow_incompatible` suggests a violation of the Liskov
Substitution Principle, meaning that a subclass is not a valid
subtype of its superclass. This Cop prevents these design smells
from occurring.

### Examples

```ruby
# bad
sig.override(allow_incompatible: true)

# good
sig.override
```

## Sorbet/BindingConstantWithoutTypeAlias

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.2.0 | -

Disallows binding the return value of `T.any`, `T.all`, `T.enum`
to a constant directly. To bind the value, one must use `T.type_alias`.

### Examples

```ruby
# bad
FooOrBar = T.any(Foo, Bar)

# good
FooOrBar = T.type_alias { T.any(Foo, Bar) }
```

## Sorbet/BuggyObsoleteStrictMemoization

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes (Unsafe) | 0.7.3 | -

Checks for the a mistaken variant of the "obsolete memoization pattern" that used to be required
for older Sorbet versions in `#typed: strict` files. The mistaken variant would overwrite the ivar with `nil`
on every call, causing the memoized value to be discarded and recomputed on every call.

This cop will correct it to read from the ivar instead of `nil`, which will memoize it correctly.

The result of this correction will be the "obsolete memoization pattern", which can further be corrected by
the `Sorbet/ObsoleteStrictMemoization` cop.

See `Sorbet/ObsoleteStrictMemoization` for more details.

### Examples

```ruby
# bad
sig { returns(Foo) }
def foo
  # This `nil` is likely a mistake, causing the memoized value to be discarded and recomputed on every call.
  @foo = T.let(nil, T.nilable(Foo))
  @foo ||= some_computation
end

# good
sig { returns(Foo) }
def foo
  # This will now memoize the value as was likely intended, so `some_computation` is only ever called once.
  # ⚠️If `some_computation` has side effects, this might be a breaking change!
  @foo = T.let(@foo, T.nilable(Foo))
  @foo ||= some_computation
end
```

## Sorbet/CallbackConditionalsBinding

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | No | Yes  | 0.7.0 | -

Ensures that callback conditionals are bound to the right type
so that they are type checked properly.

Auto-correction is unsafe because other libraries define similar style callbacks as Rails, but don't always need
binding to the attached class. Auto-correcting those usages can lead to false positives and auto-correction
introduces new typing errors.

### Examples

```ruby
# bad
class Post < ApplicationRecord
  before_create :do_it, if: -> { should_do_it? }

  def should_do_it?
    true
  end
end

# good
class Post < ApplicationRecord
  before_create :do_it, if: -> {
    T.bind(self, Post)
    should_do_it?
  }

  def should_do_it?
    true
  end
end
```

## Sorbet/CheckedTrueInSignature

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.2.0 | -

Disallows the usage of `checked(true)`. This usage could cause
confusion; it could lead some people to believe that a method would be checked
even if runtime checks have not been enabled on the class or globally.
Additionally, in the event where checks are enabled, `checked(true)` would
be redundant; only `checked(false)` or `soft` would change the behaviour.

### Examples

```ruby
# bad
sig { void.checked(true) }

# good
sig { void }
```

## Sorbet/ConstantsFromStrings

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.2.0 | -

Disallows the calls that are used to get constants fom Strings
such as +constantize+, +const_get+, and +constants+.

The goal of this cop is to make the code easier to statically analyze,
more IDE-friendly, and more predictable. It leads to code that clearly
expresses which values the constant can have.

### Examples

```ruby
# bad
class_name.constantize

# bad
constants.detect { |c| c.name == "User" }

# bad
const_get(class_name)

# good
case class_name
when "User"
  User
else
  raise ArgumentError
end

# good
{ "User" => User }.fetch(class_name)
```

## Sorbet/EmptyLineAfterSig

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.7.0 | -

Checks for blank lines after signatures.

### Examples

```ruby
# bad
sig { void }

def foo; end

# good
sig { void }
def foo; end
```

## Sorbet/EnforceSigilOrder

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.3.4 | -

Checks that the Sorbet sigil comes as the first magic comment in the file.

The expected order for magic comments is: (en)?coding, typed, warn_indent then frozen_string_literal.

For example, the following bad ordering:

```ruby
# frozen_string_literal: true
# typed: true
class Foo; end
```

Will be corrected as:

```ruby
# typed: true
# frozen_string_literal: true
class Foo; end
```

Only `(en)?coding`, `typed`, `warn_indent` and `frozen_string_literal` magic comments are considered,
other comments or magic comments are left in the same place.

## Sorbet/EnforceSignatures

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.4 | -

Checks that every method definition and attribute accessor has a Sorbet signature.

It also suggest an autocorrect with placeholders so the following code:

```
def foo(a, b, c); end
```

Will be corrected as:

```
sig { params(a: T.untyped, b: T.untyped, c: T.untyped).returns(T.untyped)
def foo(a, b, c); end
```

You can configure the placeholders used by changing the following options:

* `ParameterTypePlaceholder`: placeholders used for parameter types (default: 'T.untyped')
* `ReturnTypePlaceholder`: placeholders used for return types (default: 'T.untyped')

## Sorbet/EnforceSingleSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.7.0 | -

Checks that there is only one Sorbet sigil in a given file

For example, the following class with two sigils

```ruby
# typed: true
# typed: true
# frozen_string_literal: true
class Foo; end
```

Will be corrected as:

```ruby
# typed: true
# frozen_string_literal: true
class Foo; end
```

Other comments or magic comments are left in place.

## Sorbet/FalseSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.3.3 | -

Makes the Sorbet `false` sigil mandatory in all files.

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
SuggestedStrictness | `false` | String
Include | `**/*.{rb,rbi,rake,ru}` | Array
Exclude | `bin/**/*`, `db/**/*.rb`, `script/**/*` | Array

## Sorbet/ForbidExtendTSigHelpersInShims

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.6.0 | -

Ensures RBI shims do not include a call to extend T::Sig
or to extend T::Helpers

### Examples

```ruby
# bad
module SomeModule
  extend T::Sig
  extend T::Helpers

  sig { returns(String) }
  def foo; end
end

# good
module SomeModule
  sig { returns(String) }
  def foo; end
end
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
Include | `**/*.rbi` | Array

## Sorbet/ForbidIncludeConstLiteral

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.2.0 | 0.5.0

Correct `send` expressions in include statements by constant literals.

Sorbet, the static checker, is not (yet) able to support constructs on the
following form:

```ruby
class MyClass
  include send_expr
end
```

Multiple occurences of this can be found in Shopify's code base like:

```ruby
include Rails.application.routes.url_helpers
```
or
```ruby
include Polaris::Engine.helpers
```

## Sorbet/ForbidRBIOutsideOfAllowedPaths

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.6.1 | -

Makes sure that RBI files are always located under the defined allowed paths.

Options:

* `AllowedPaths`: A list of the paths where RBI files are allowed (default: ["rbi/**", "sorbet/rbi/**"])

### Examples

```ruby
# bad
# lib/some_file.rbi
# other_file.rbi

# good
# rbi/external_interface.rbi
# sorbet/rbi/some_file.rbi
# sorbet/rbi/any/path/for/file.rbi
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
AllowedPaths | `rbi/**`, `sorbet/rbi/**` | Array
Include | `**/*.rbi` | Array

## Sorbet/ForbidSuperclassConstLiteral

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | 0.2.0 | 0.6.1

Correct superclass `send` expressions by constant literals.

Sorbet, the static checker, is not (yet) able to support constructs on the
following form:

```ruby
class Foo < send_expr; end
```

Multiple occurences of this can be found in Shopify's code base like:

```ruby
class ShopScope < Component::TrustedIdScope[ShopIdentity::ShopId]
```
or
```ruby
class ApiClientEligibility < Struct.new(:api_client, :match_results, :shop)
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
Exclude | `db/migrate/*.rb` | Array

## Sorbet/ForbidTStruct

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | No | Yes  | <<next>> | <<next>>

Disallow using `T::Struct` and `T::Props`.

### Examples

```ruby
# bad
class MyStruct < T::Struct
  const :foo, String
  prop :bar, Integer, default: 0

  def some_method; end
end

# good
class MyStruct
  extend T::Sig

  sig { returns(String) }
  attr_reader :foo

  sig { returns(Integer) }
  attr_accessor :bar

  sig { params(foo: String, bar: Integer) }
  def initialize(foo:, bar: 0)
    @foo = foo
    @bar = bar
  end

  def some_method; end
end
```

## Sorbet/ForbidTUnsafe

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | 0.7.0 | 0.7.0

Disallows using `T.unsafe` anywhere.

### Examples

```ruby
# bad
T.unsafe(foo)

# good
foo
```

## Sorbet/ForbidTUntyped

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | 0.6.9 | 0.7.0

Disallows using `T.untyped` anywhere.

### Examples

```ruby
# bad
sig { params(my_argument: T.untyped).void }
def foo(my_argument); end

# good
sig { params(my_argument: String).void }
def foo(my_argument); end
```

## Sorbet/ForbidTypeAliasedShapes

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | 0.7.6 | -

Disallows defining type aliases that contain shapes

### Examples

```ruby
# bad
Foo = T.type_alias { { foo: Integer } }

# good
class Foo
  extend T::Sig

  sig { params(foo: Integer).void }
  def initialize(foo)
    @foo = foo
  end
end
```

## Sorbet/ForbidUntypedStructProps

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.4.0 | -

Disallows use of `T.untyped` or `T.nilable(T.untyped)`
as a prop type for `T::Struct` or `T::ImmutableStruct`.

### Examples

```ruby
# bad
class SomeClass < T::Struct
  const :foo, T.untyped
  prop :bar, T.nilable(T.untyped)
end

# good
class SomeClass < T::Struct
  const :foo, Integer
  prop :bar, T.nilable(String)
end
```

## Sorbet/HasSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

Makes the Sorbet typed sigil mandatory in all files.

Options:

* `SuggestedStrictness`: Sorbet strictness level suggested in offense messages (default: 'false')
* `MinimumStrictness`: If set, make offense if the strictness level in the file is below this one

If a `MinimumStrictness` level is specified, it will be used in offense messages and autocorrect.

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
SuggestedStrictness | `false` | String
MinimumStrictness | `nil` | String
ExactStrictness | `nil` | String
Include | `**/*.{rb,rbi,rake,ru}` | Array
Exclude | `bin/**/*`, `db/**/*.rb`, `script/**/*` | Array

## Sorbet/IgnoreSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

Makes the Sorbet `ignore` sigil mandatory in all files.

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
SuggestedStrictness | `ignore` | String
Include | `**/*.{rb,rbi,rake,ru}` | Array
Exclude | `bin/**/*`, `db/**/*.rb`, `script/**/*` | Array

## Sorbet/ImplicitConversionMethod

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | No | <<next>> | -

Disallows declaring implicit conversion methods.
Since Sorbet is a nominal (not structural) type system,
implicit conversion is currently unsupported.

### Examples

```ruby
# bad
def to_str; end

# good
def to_str(x); end

# bad
def self.to_str; end

# good
def self.to_str(x); end

# bad
alias to_str to_s
```

## Sorbet/KeywordArgumentOrdering

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.2.0 | -

Checks for the ordering of keyword arguments required by
sorbet-runtime. The ordering requires that all keyword arguments
are at the end of the parameters list, and all keyword arguments
with a default value must be after those without default values.

### Examples

```ruby
# bad
sig { params(a: Integer, b: String).void }
def foo(a: 1, b:); end

# good
sig { params(b: String, a: Integer).void }
def foo(b:, a: 1); end
```

## Sorbet/ObsoleteStrictMemoization

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.7.1 | -

Checks for the obsolete pattern for initializing instance variables that was required for older Sorbet
versions in `#typed: strict` files.

It's no longer required, as of Sorbet 0.5.10210
See https://sorbet.org/docs/type-assertions#put-type-assertions-behind-memoization

### Examples

```ruby
# bad
sig { returns(Foo) }
def foo
  @foo = T.let(@foo, T.nilable(Foo))
  @foo ||= Foo.new
end

# bad
sig { returns(Foo) }
def foo
  # This would have been a mistake, causing the memoized value to be discarded and recomputed on every call.
  @foo = T.let(nil, T.nilable(Foo))
  @foo ||= Foo.new
end

# good
sig { returns(Foo) }
def foo
  @foo ||= T.let(Foo.new, T.nilable(Foo))
end
```

## Sorbet/OneAncestorPerLine

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.6.0 | -

Ensures one ancestor per requires_ancestor line
rather than chaining them as a comma-separated list.

### Examples

```ruby
# bad
module SomeModule
  requires_ancestor Kernel, Minitest::Assertions
end

# good
module SomeModule
  requires_ancestor Kernel
  requires_ancestor Minitest::Assertions
end
```

## Sorbet/RedundantExtendTSig

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | No | Yes  | 0.7.0 | -

Forbids the use of redundant `extend T::Sig`. Only for use in
applications that monkey patch `Module.include(T::Sig)` globally,
which would make it redundant.

### Examples

```ruby
# bad
class Example
  extend T::Sig
  sig { void }
  def no_op; end
end

# good
class Example
  sig { void }
  def no_op; end
end
```

## Sorbet/SignatureBuildOrder

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.3.0 | -

Checks for the correct order of sig builder methods:
- abstract, override, or overridable
- type_parameters
- params
- returns, or void
- soft, checked, or on_failure

 # bad
 sig { returns(Integer).params(x: Integer) }

 # good
 sig { params(x: Integer).returns(Integer) }

### Examples

```ruby
# bad
sig { void.abstract }

# good
sig { abstract.void }
```

## Sorbet/SingleLineRbiClassModuleDefinitions

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.6.0 | -

Ensures empty class/module definitions in RBI files are
done on a single line rather than being split across multiple lines.

### Examples

```ruby
# bad
module SomeModule
end

# good
module SomeModule; end
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
Include | `**/*.rbi` | Array

## Sorbet/StrictSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

Makes the Sorbet `strict` sigil mandatory in all files.

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
SuggestedStrictness | `strict` | String
Include | `**/*.{rb,rbi,rake,ru}` | Array
Exclude | `bin/**/*`, `db/**/*.rb`, `script/**/*` | Array

## Sorbet/StrongSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

Makes the Sorbet `strong` sigil mandatory in all files.

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
SuggestedStrictness | `strong` | String
Include | `**/*.{rb,rbi,rake,ru}` | Array
Exclude | `bin/**/*`, `db/**/*.rb`, `script/**/*` | Array

## Sorbet/TStructPropertyAttrMacro

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | <<next>> | -

Checks for the use of `attr_*` methods matching a `const` or `prop` in a `T::Struct`.

### Examples

```ruby
# bad – pointless `attr_*` method
class Foo < T::Struct
  attr_reader :bar
  attr_reader :biz
  attr_writer :biz
  attr_accessor :baz

  const :bar, String
  prop :biz, String
  prop :baz, String
end

# good
class Foo < T::Struct
  const :bar, String
  prop :biz, String
  prop :baz, String
end
```
```ruby
# bad – defining writer method for `const` property
class Foo < T::Struct
  attr_writer :bar
  attr_accessor :biz

  const :bar, String
  const :biz, String
end

# good – mutable property defined with `prop`
class Foo < T::Struct
  prop :bar, String
  prop :biz, String
end
```
```ruby
# good – customized attribute access – although this is not a recommended pattern with T::Struct
class Foo < T::Struct
  const :bar, String
  prop :biz, String

  def bar
    # ...
  end

  def biz=(value)
    # ...
  end
end
```

## Sorbet/TrueSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

Makes the Sorbet `true` sigil mandatory in all files.

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
SuggestedStrictness | `true` | String
Include | `**/*.{rb,rbi,rake,ru}` | Array
Exclude | `bin/**/*`, `db/**/*.rb`, `script/**/*` | Array

## Sorbet/TypeAliasName

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.6.6 | -

Ensures all constants used as `T.type_alias` are using CamelCase.

### Examples

```ruby
# bad
FOO_OR_BAR = T.type_alias { T.any(Foo, Bar) }

# good
FooOrBar = T.type_alias { T.any(Foo, Bar) }
```

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
Include | `**/*.{rb,rbi,rake,ru}` | Array
Exclude | `bin/**/*`, `db/**/*.rb`, `script/**/*` | Array

## Sorbet/ValidSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.3.3 | -

Checks that every Ruby file contains a valid Sorbet sigil.
Adapted from: https://gist.github.com/clarkdave/85aca4e16f33fd52aceb6a0a29936e52

Options:

* `RequireSigilOnAllFiles`: make offense if the Sorbet typed is not found in the file (default: false)
* `SuggestedStrictness`: Sorbet strictness level suggested in offense messages (default: 'false')
* `MinimumStrictness`: If set, make offense if the strictness level in the file is below this one
* `ExactStrictness`: If set, make offense if the strictness level in the file is different than this one

If an `ExactStrictness` level is specified, it will be used in offense messages and autocorrect.
Otherwise, if a `MinimumStrictness` level is specified, it will be used in offense messages and autocorrect.

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
RequireSigilOnAllFiles | `false` | Boolean
SuggestedStrictness | `false` | String
MinimumStrictness | `nil` | String
ExactStrictness | `nil` | String
Include | `**/*.{rb,rbi,rake,ru}` | Array
Exclude | `bin/**/*`, `db/**/*.rb`, `script/**/*` | Array
