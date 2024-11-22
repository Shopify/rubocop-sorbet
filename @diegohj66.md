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
require: rubocop-sorbet
```

Alternatively, use the following array notation when specifying multiple extensions:

```yaml
require:
  - rubocop-other-extension
  - rubocop-sorbet
```

Now you can run `rubocop` and it will automatically load the RuboCop Sorbet cops together with the standard cops.

### Command line

```sh
rubocop --require rubocop-sorbet
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-sorbet'
end
```

### Rubocop rules for RBI files

To enable the cops related to RBI files under the `sorbet/rbi/` directory, put this in `sorbet/rbi/.rubocop.yml`:

```yaml
inherit_gem:
  rubocop-sorbet: config/rbi.yml
```

This will turn off default cops for `**/*.rbi` files and enable the RBI specific cops.

You'll also need to add an entry to the main `.rubocop.yml` so that RBI files are included, e.g.:

```yaml
AllCops:
  Include:
    - "sorbet/rbi/shims/**/*.rbi"
```

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
- Ruby >= 2.5

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Shopify/rubocop-sorbet. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

To contribute a new cop, please use the supplied generator like this:

```sh
bundle exec rake "new_cop[Sorbet/NewCopName]"
```

which will create a skeleton cop, a skeleton spec, an entry in the default config file and will require the new cop so that it is properly exported from the gem.

Don't forget to update the documentation with:

```sh
bundle exec rake generate_cops_documentation
```

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/rubocop-sorbet/blob/main/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Rubocop::Sorbet project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Shopify/rubocop-sorbet/blob/main/CODE_OF_CONDUCT.md).
