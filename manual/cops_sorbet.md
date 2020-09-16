# Sorbet

## Sorbet/AllowIncompatibleOverride

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.2.0 | -

This cop disallows using `.override(allow_incompatible: true)`.
Using `allow_incompatible` suggests a violation of the Liskov
Substitution Principle, meaning that a subclass is not a valid
subtype of it's superclass. This Cop prevents these design smells
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

This cop disallows binding the return value of `T.any`, `T.all`, `T.enum`
to a constant directly. To bind the value, one must use `T.type_alias`.

### Examples

```ruby
# bad
FooOrBar = T.any(Foo, Bar)

# good
FooOrBar = T.type_alias { T.any(Foo, Bar) }
```

## Sorbet/CheckedTrueInSignature

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.2.0 | -

This cop disallows the usage of `checked(true)`. This usage could cause
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

This cop disallows the calls that are used to get constants fom Strings
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

## Sorbet/EnforceSigilOrder

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.3.4 | -

This cop checks that the Sorbet sigil comes as the first magic comment in the file.

The expected order for magic comments is: typed, (en)?coding, warn_indent then frozen_string_literal.

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

Only `typed`, `(en)?coding`, `warn_indent` and `frozen_string_literal` magic comments are considered,
other comments or magic comments are left in the same place.

## Sorbet/EnforceSignatures

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.4 | -

This cop checks that every method definition and attribute accessor has a Sorbet signature.

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

## Sorbet/FalseSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.3.3 | -

This cop makes the Sorbet `false` sigil mandatory in all files.

### Configurable attributes

Name | Default value | Configurable values
--- | --- | ---
SuggestedStrictness | `true` | Boolean
Include | `**/*.rb`, `**/*.rbi`, `**/*.rake`, `**/*.ru` | Array
Exclude | `bin/**/*`, `db/**/*.rb`, `script/**/*` | Array

## Sorbet/ForbidIncludeConstLiteral

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.2.0 | 0.5.0

No documentation

## Sorbet/ForbidSuperclassConstLiteral

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.2.0 | 0.5.0

No documentation

## Sorbet/ForbidUntypedStructProps

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.3.8 | -

This cop disallows use of `T.untyped` or `T.nilable(T.untyped)`
as a prop type for `T::Struct`.

### Examples

```ruby
# bad
class SomeClass
  const :foo, T.untyped
  prop :bar, T.nilable(T.untyped)
end

# good
class SomeClass
  const :foo, Integer
  prop :bar, T.nilable(String)
end
```

## Sorbet/HasSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

This cop makes the Sorbet typed sigil mandatory in all files.

Options:

* `SuggestedStrictness`: Sorbet strictness level suggested in offense messages (default: 'false')
* `MinimumStrictness`: If set, make offense if the strictness level in the file is below this one

If a `MinimumStrictness` level is specified, it will be used in offense messages and autocorrect.

## Sorbet/IgnoreSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

This cop makes the Sorbet `ignore` sigil mandatory in all files.

## Sorbet/KeywordArgumentOrdering

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.2.0 | -

This cop checks for the ordering of keyword arguments required by
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

## Sorbet/ParametersOrderingInSignature

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | 0.2.0 | -

This cop checks for inconsistent ordering of parameters between the
signature and the method definition. The sorbet-runtime gem raises
when such inconsistency occurs.

### Examples

```ruby
# bad
sig { params(a: Integer, b: String).void }
def foo(b:, a:); end

# good
sig { params(a: Integer, b: String).void }
def foo(a:, b:); end
```

## Sorbet/SignatureBuildOrder

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.3.0 | -

No documentation

## Sorbet/SignatureCop

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | No | - | -

Abstract cop specific to Sorbet signatures

You can subclass it to use the `on_signature` trigger and the `signature?` node matcher.

## Sorbet/StrictSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

This cop makes the Sorbet `strict` sigil mandatory in all files.

## Sorbet/StrongSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

This cop makes the Sorbet `strong` sigil mandatory in all files.

## Sorbet/TrueSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Disabled | Yes | Yes  | 0.3.3 | -

This cop makes the Sorbet `true` sigil mandatory in all files.

## Sorbet/ValidSigil

Enabled by default | Safe | Supports autocorrection | VersionAdded | VersionChanged
--- | --- | --- | --- | ---
Enabled | Yes | Yes  | 0.3.3 | -

This cop checks that every Ruby file contains a valid Sorbet sigil.
Adapted from: https://gist.github.com/clarkdave/85aca4e16f33fd52aceb6a0a29936e52

Options:

* `RequireSigilOnAllFiles`: make offense if the Sorbet typed is not found in the file (default: false)
* `SuggestedStrictness`: Sorbet strictness level suggested in offense messages (default: 'false')
* `MinimumStrictness`: If set, make offense if the strictness level in the file is below this one

If a `MinimumStrictness` level is specified, it will be used in offense messages and autocorrect.
