# CouchRest Model

[![Build Status](https://travis-ci.org/couchrest/couchrest_model.png)](https://travis-ci.org/couchrest/couchrest_model)

CouchRest Model helps you define models that are stored as documents in your CouchDB database.

It supports useful features such as setting properties with typecasting, callbacks, validations, associations, and helps
with creating CouchDB views to access your data.

CouchRest Model uses ActiveModel for a lot of the magic, so if you're using Rails, you'll need at least version 3.0. The latest release (since 2.0.0) is Rails 4.0 compatible, and we recommend Ruby 2.0+.

## Documentation

Please visit the documentation project at [http://www.couchrest.info](http://www.couchrest.info). Your [contributions](https://github.com/couchrest/couchrest.github.com) would be greatly appreciated!

General API: [http://rdoc.info/projects/couchrest/couchrest_model](http://rdoc.info/projects/couchrest/couchrest_model)

See the [update history](https://github.com/couchrest/couchrest_model/blob/master/history.md) for an up to date list of all the changes we've been working on recently.

### Upgrading from an earlier version?

*Pre 2.0:* As of June 2012, couchrest model no longer supports the `view_by` and `view` calls from the model. Views are no only accessed via a design document. If you have older code and wish to upgrade, please ensure you move to the new syntax for using views.

*Pre 1.1:* As of April 2011 and the release of version 1.1.0, the default model type key is 'type' instead of 'couchrest-type'. Simply updating your project will not work unless you migrate your data or set the configuration option in your initializers:

```ruby
CouchRest::Model::Base.configure do |config|
  config.model_type_key = 'couchrest-type'
end
```

## Install

### Gem

```bash
$ sudo gem install couchrest_model
```

### Bundler

If you're using bundler, define a line similar to the following in your project's Gemfile:

```ruby
gem 'couchrest_model'
```

### Configuration

CouchRest Model is configured to work out the box with no configuration as long as your CouchDB instance is running on the default port (5984) on localhost. The default name of the database is either the name of your application as provided by the `Rails.application.class.to_s` call (with /application removed) or just 'couchrest' if none is available.

The library will try to detect a configuration file at `config/couchdb.yml` from the Rails root or `Dir.pwd`. Here you can configuration your database connection in a Rails-like way:

    development:
      protocol: 'https'
      host: sample.cloudant.com
      port: 443
      prefix: project
      suffix: test
      username: test
      password: user

Note that the name of the database is either just the prefix and suffix combined or the prefix plus any text you specifify using `use_database` method in your models with the suffix on the end.

The example config above for example would use a database called "project_test". Heres an example using the `use_database` call:

```ruby
class Project < CouchRest::Model::Base
  use_database 'sample'
end

# The database object would be provided as:
Project.database     #=> "https://test:user@sample.cloudant.com:443/project_sample_test"
```

### Using instead of ActiveRecord in Rails

A common use case for a new project is to replace ActiveRecord with CouchRest Model, although they should work perfectly well together. If you no longer want to depend on ActiveRecord or any of its sub-dependencies such as sqlite, update your `config/application.rb` so the top looks something like:

```ruby
# We don't need active record, so load everything but:
# require 'rails/all'
require 'action_controller/railtie'
require 'action_mailer/railtie'
require 'rails/test_unit/railtie'
```

You'll then need to make sure any references to `config.active_record` are removed from your environment files.

## Generators

### Configuration

```bash
$ rails generate couchrest_model:config
```

### Model

```bash
$ rails generate model person --orm=couchrest_model
```

## General Usage 

```ruby
require 'couchrest_model'

class Cat < CouchRest::Model::Base

  property :name,      String
  property :lives,     Integer, :default => 9

  property :nicknames, [String]

  timestamps!

  design do
    view :by_name
  end

end

@cat = Cat.new(:name => 'Felix', :nicknames => ['so cute', 'sweet kitty'])

@cat.new?   # true
@cat.save

@cat['name']   # "Felix"

@cat.nicknames << 'getoffdamntable'

@cat = Cat.new
@cat.update_attributes(:name => 'Felix', :random_text => 'feline')
@cat.new? # false
@cat.random_text  # Raises error!
```

## Development

### Preparations

CouchRest Model now comes with a Gemfile to help with development. If you want to make changes to the code, download a copy then run:

```bash
bundle install
```

That should set everything up for `rake spec` to be run correctly. Update the couchrest_model.gemspec if your alterations
use different gems.

### Testing

The most complete documentation is the spec/ directory. To validate your CouchRest install, from the project root directory run `bundle install` to ensure all the development dependencies are available and then `rspec spec` or `bundle exec rspec spec`.

We will not accept pull requests to the project without sufficient tests.

## Contact

Please post bugs, suggestions and patches to the bug tracker at [http://github.com/couchrest/couchrest_model/issues](http://github.com/couchrest/couchrest_model/issues).

Follow us on Twitter: [http://twitter.com/couchrest](http://twitter.com/couchrest)

Also, check [https://twitter.com/search?q=couchrest](https://twitter.com/search?q=couchrest)


