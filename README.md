# Rubocop-Sorbet

A collection of Rubocop rules for Sorbet.

## Installation

Just install the `rubocop-sorbet` gem

```sh
gem install rubocop-sorbet
```
or, if you use `Bundler`, add this line your application's `Gemfile`:

```ruby
gem 'rubocop-sorbet', require: false
```

## Usage

You need to tell RuboCop to load the Sorbet extension. There are three ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`:

```yaml
plugins: rubocop-sorbet
```

Alternatively, use the following array notation when specifying multiple extensions:

```yaml
plugins:
  - rubocop-sorbet
  - rubocop-other-extension
```

Now you can run `rubocop` and it will automatically load the RuboCop Sorbet cops together with the standard cops.

> [!NOTE]
> The plugin system is supported in RuboCop 1.72+. In earlier versions, use `require` instead of `plugins`.

### Command line

```sh
rubocop --plugin rubocop-sorbet
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.plugins << 'rubocop-sorbet'
end
```

### Rubocop rules for RBI files

To enable the cops related to RBI files under the `sorbet/rbi/` directory, put this in `sorbet/rbi/.rubocop.yml`:

```yaml
inherit_gem:
  rubocop-sorbet: config/rbi.yml
```
> [!NOTE]
> If your top-level `.rubocop.yml` does not load `rubocop-sorbet`, you might need to also add a `require: rubocop-sorbet` or `plugins: rubocop-sorbet` to the `sorbet/rbi/.rubocop.yml` file at the top.

This will turn off default cops for `**/*.rbi` files and enable the RBI specific cops.

You'll also need to add an entry to the main `.rubocop.yml` so that RBI files are included, e.g.:

```yaml
AllCops:
  Include:
    - "sorbet/rbi/shims/**/*.rbi"
```

### Prefer RBS comments

For code that has adopted Sorbet's RBS comments, inherit the RBS preset:

```yaml
plugins:
  - rubocop-sorbet

inherit_gem:
  rubocop-sorbet: config/rbs.yml
```

The preset requires RBS signatures on methods and attribute accessors. It forbids
`sig`, `T::Sig.sig`, `T::Sig::WithoutRuntime.sig`, `extend`/`include T::Sig` and
`T::Helpers`, `T.type_alias`, `T.untyped`, and the assertion methods `T.let`,
`T.cast`, `T.must`, `T.unsafe`, `T.absurd`, and `T.bind`. Other cops retain their
default checks, so they can still check Sorbet syntax allowed by local exceptions.
Autocorrection is disabled for `BindingConstantWithoutTypeAlias`,
`ObsoleteStrictMemoization`, and `ForbidSigWithoutRuntime` because their corrections
can produce syntax forbidden by this preset.

This uses the existing cops, which check for RBS signature comments without
validating their types. Sorbet remains responsible for type checking. The preset
does not forbid `T::Enum` or `T::Struct`, or every other `sorbet-runtime` feature.

Enable Sorbet's experimental RBS comment support by adding both flags to
`sorbet/config`, as described in the [RBS support guide](https://sorbet.org/docs/rbs-support#enabling-rbs-comments):

```text
--parser=prism
--enable-experimental-rbs-comments
```

The preset requires a signature on every method and attribute accessor, including
in `typed: false` files. To choose RBS syntax without requiring every method to have
a signature, override `Sorbet/EnforceSignatures` with `Enabled: false`. The
`ForbidSig` cops still reject Sorbet signature blocks.

For incremental adoption, apply the preset in a migrated directory's
`.rubocop.yml`. Load `rubocop-sorbet` in the root configuration, then use, for
example, `app/.rubocop.yml`:

```yaml
inherit_from: ../.rubocop.yml

inherit_gem:
  rubocop-sorbet: config/rbs.yml
```

Keep the [RBI preset](#rubocop-rules-for-rbi-files) in `sorbet/rbi/.rubocop.yml`.
Inheriting the RBI preset does not undo an RBS policy inherited from the root.
Scope the RBS preset to migrated Ruby directories when RBI or legacy Ruby files
still use `sig` blocks.

RuboCop supports multiple inherited configurations. Later inherited files override
earlier ones; local settings override inherited values. When combining this preset
with optional cops such as `CallbackConditionalsBinding`, `ForbidIncludeConstLiteral`,
or `ForbidTStruct`, review their autocorrection settings: they can generate Ruby
annotations that this preset forbids.

This preset configures the existing cops rather than banning every Sorbet API.
It does not check `T::Generic`, `T.assert_type!`, or `T.must_because`. Run Sorbet to
validate RBS syntax and types after autocorrection. Missing signatures receive
`untyped` placeholders; forwarding and destructured parameters require a manually
written signature.

## The Cops
All cops are located under [`lib/rubocop/cop/sorbet`](lib/rubocop/cop/sorbet), and contain examples/documentation.

In your `.rubocop.yml`, you may treat the Sorbet cops just like any other cop. For example:

```yaml
Sorbet/FalseSigil:
  Exclude:
    - lib/example.rb
```

## Documentation

You can read about each cop supplied by RuboCop Sorbet in [the manual](manual/cops.md).

## Compatibility

Sorbet cops support the following versions:

- Sorbet >= 0.5
- Ruby >= 3.1

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on how to contribute to this project.

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/rubocop-sorbet/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Rubocop::Sorbet project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Shopify/rubocop-sorbet/blob/main/CODE_OF_CONDUCT.md).
