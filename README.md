# Rubocop-Sorbet

[![Build Status](https://travis-ci.org/Shopify/rubocop-sorbet.svg?branch=master)](https://travis-ci.org/Shopify/rubocop-sorbet)

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

Note: in order to use the [Sorbet/SignatureBuildOrder](https://github.com/Shopify/rubocop-sorbet/blob/master/manual/cops_sorbet.md#sorbetsignaturebuildorder) cop autocorrect feature, it is necessary
to install `unparser` in addition to `rubocop-sorbet`.

```ruby
gem "unparser", require: false
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
bundle exec rake new_cop[Sorbet/NewCopName]
```

which will create a skeleton cop, a skeleton spec, an entry in the default config file and will require the new cop so that it is properly exported from the gem.

## License

The gem is available as open source under the terms of the [MIT License](https://github.com/Shopify/rubocop-sorbet/blob/master/LICENSE.txt).

## Code of Conduct

Everyone interacting in the Rubocop::Sorbet project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/Shopify/rubocop-sorbet/blob/master/CODE_OF_CONDUCT.md).
