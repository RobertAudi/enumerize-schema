EnumeratedAttribute
===================

[![RSpec](https://github.com/RobertAudi/EnumeratedAttribute/actions/workflows/rspec.yml/badge.svg)](https://github.com/RobertAudi/EnumeratedAttribute/actions/workflows/rspec.yml)
[![Standard](https://github.com/RobertAudi/EnumeratedAttribute/actions/workflows/standard.yml/badge.svg)](https://github.com/RobertAudi/EnumeratedAttribute/actions/workflows/standard.yml)

EnumeratedAttribute is wrapper around [Enumerize](https://github.com/brainspec/enumerize) that enables storing enum values in schema files.

Installation
------------

Add this line to your application's Gemfile:

```ruby
gem "enumerated_attribute"
```

And then execute:

```console
$ bundle install
```

Usage
-----

Instead of using `extend Enumerize`, use `include EnumeratedAttribute` instead and define your enums with `attr_enum`:

```ruby
class User
  include EnumeratedAttribute

  attr_enum :role
end
```

The values of the enum need to be listed in a YAML schema file. Here are the default paths for the schema file:

- `config/enumerated_attribute.yml` in Ruby on Rails applications
- `enumerated_attribute.yml` under `Bundler.root` (if Bundler is used) or the current working directory

The structure of the schema file is similar to the one of I18n locale files:

```yaml
---
user:
  role:
    - member
    - moderator
    - administrator
```

### Options

Options are forwarded to `enumerize`. If the `:in` option is specified then `attr_enum` will not check the schema file and the `:in` option will also be forwarded to `enumerize`.

Development
-----------

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Contributing
------------

Bug reports and pull requests are welcome on GitHub at https://github.com/RobertAudi/enumerated_attribute.

License
-------

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
