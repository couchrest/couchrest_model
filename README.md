# CouchRest Model: CouchDB, close to shiny metal with rounded edges

CouchRest Models adds additional functionality to the standard CouchRest Document class such as
setting properties, callbacks, typecasting, and validations.

For more documentation see [http://www.couchrest.info](http://www.couchrest.info).

Originally called ExtendedDocument, the new Model structure uses ActiveModel, part of Rails 3, 
for validations and callbacks.

If your project is still running Rails 2.3, you'll have to continue using ExtendedDocument as 
it is not possible to load ActiveModel into programs that do not use ActiveSupport 3.0.

CouchRest Model is only properly tested on CouchDB version 1.0 or newer.

*WARNING:* As of April 2011 and the release of version 1.1.0, the default model type key is 'model' instead of 'couchrest-type'. Simply updating your project will not work unless you migrate your data or set the configuration option in your initializers:

    CouchRest::Model::Base.configure do |config|
      config.model_type_key = 'couchrest-type'
    end

This is because CouchRest Model's are not couchrest specific and may be used in any other system such as a Javascript library, the model type should reflect this.

## Install

### Gem

    $ sudo gem install couchrest_model

### Bundler

If you're using bundler, define a line similar to the following in your project's Gemfile:

    gem 'couchrest_model'

You might also consider using the latest git repository. We try to make sure the current version in git is stable and at the very least all tests should pass.

    gem 'couchrest_model', :git => 'git://github.com/couchrest/couchrest_model.git'

### Setup

There is currently no standard way for telling CouchRest Model how it should access your database, this is something we're still working on. For the time being, the easiest way is to set a COUCHDB_DATABASE global variable to an instance of CouchRest Database, and call `use_database COUCHDB_DATABASE` in each model.

TODO: Add an example!

### Development

CouchRest Model now comes with a Gemfile to help with development. If you want to make changes to the code, download a copy then run:

    bundle install

That should set everything up for `rake spec` to be run correctly. Update the couchrest_model.gemspec if your alterations
use different gems.

## Generators

### Model

    $ rails generate model person --orm=couchrest_model

## General Usage 

    require 'couchrest_model'

    class Cat < CouchRest::Model::Base

      property :name,      String
      property :lives,     Integer, :default => 9

      property :nicknames, [String]

      timestamps!

      view_by :name

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



## Testing

The most complete documentation is the spec/ directory. To validate your CouchRest install, from the project root directory run `bundle install` to ensure all the development dependencies are available and then `rspec spec` or `bundle exec rspec spec`.

We will not accept pull requests to the project without sufficient tests.

## Docs

API: [http://rdoc.info/projects/couchrest/couchrest_model](http://rdoc.info/projects/couchrest/couchrest_model)

Check the wiki for documentation and examples [http://wiki.github.com/couchrest/couchrest_model](http://wiki.github.com/couchrest/couchrest_model)


## Contact

Please post bugs, suggestions and patches to the bug tracker at [http://github.com/couchrest/couchrest_model/issues](http://github.com/couchrest/couchrest_model/issues).

Follow us on Twitter: [http://twitter.com/couchrest](http://twitter.com/couchrest)

Also, check [http://twitter.com/#search?q=%23couchrest](http://twitter.com/#search?q=%23couchrest)

