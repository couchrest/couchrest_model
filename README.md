# CouchRest Model: CouchDB, close to shiny metal with rounded edges

CouchRest Models adds additional functionality to the standard CouchRest Document class such as
setting properties, callbacks, typecasting, and validations.

Originally called ExtendedDocument, the new Model structure uses ActiveModel, part of Rails 3, 
for validations and callbacks.

If your project is still running Rails 2.3, you'll have to continue using ExtendedDocument as 
it is not possible to load ActiveModel into programs that do not use ActiveSupport 3.0.

CouchRest Model only supports CouchDB 0.10.0 or newer.

## Install

    $ sudo gem install couchrest_model
   
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


## Properties

Only attributes with a property definition will be stored be CouchRest Model (as opposed
to a normal CouchRest Document which will store everything). To help prevent confusion, 
a property should be considered as the definition of an attribute. An attribute must be associated
with a property, but a property may not have any attributes associated if none have been set.


In its simplest form, a property
will only create a getter and setter passing all attribute data directly to the database. Assuming the attribute
provided responds to +to_json+, there will not be any problems saving it, but when loading the 
data back it will either be a string, number, array, or hash:

    class Cat < CouchRest::Model::Base
      property :name
      property :birthday
    end

    @cat = Cat.new(:name => 'Felix', :birthday => 2.years.ago)
    @cat.name        # 'Felix'
    @cat.birthday.is_a?(Time)  # True!
    @cat.save
    @cat = Cat.find(@cat.id)
    @cat.name        # 'Felix'
    @cat.birthday.is_a?(Time)  # False!

Properties create getters and setters similar to the following:

    def name
      read_attribute('name')
    end

    def name=(value)
      write_attribute('name', value)
    end

Properties can also have a type which 
will be used for casting data retrieved from CouchDB when the attribute is set:

    class Cat < CouchRest::Model::Base
      property :name, String
      property :last_fed_at, Time
    end

    @cat = Cat.new(:name => 'Felix', :last_fed_at => 10.minutes.ago)
    @cat.last_fed_at.is_a?(Time)   # True!
    @cat.save
    @cat = Cat.find(@cat.id)
    @cat.last_fed_at < 20.minutes.ago   # True!


Booleans or TrueClass will also create a getter with question mark at the end:

    class Cat < CouchRest::Model::Base
      property :awake, TrueClass, :default => true
    end

    @cat.awake?   # true

Adding the +:default+ option will ensure the attribute always has a value.

Defining a property as read-only will mean that its value is set only when read from the
database and that it will not have a setter method. You can however update a read-only
attribute using the +write_attribute+ method:

    class Cat < CouchRest::Model::Base
      property :name, String
      property :lives, Integer, :default => 9, :readonly => true  

      def fall_off_balcony!
        write_attribute(:lives, lives - 1)
        save
      end
    end

    @cat = Cat.new(:name => "Felix")
    @cat.fall_off_balcony!
    @cat.lives    # Now 8!


## Property Arrays

An attribute may also contain an array of data. CouchRest Model handles this, along
with casting, by defining the class of the child attributes inside an Array:

    class Cat < CouchRest::Model::Base
      property :name, String
      property :nicknames, [String]
    end

By default, the array will be ready to use from the moment the object as been instantiated:

    @cat = Cat.new(:name => 'Fluffy')
    @cat.nicknames << 'Buffy'

    @cat.nicknames == ['Buffy']

When anything other than a string is set as the class of a property, the array will be converted
into special wrapper called a CastedArray. If the child objects respond to the 'casted_by' method
(such as those created with CastedModel, below) it will contain a reference to the parent.

## Casted Models

CouchRest Model allows you to take full advantage of CouchDB's ability to store complex 
documents and retrieve them using the CastedModel module. Simply include the module in
a Hash (or other model that responds to the [] and []= methods) and set any properties
you'd like to use. For example:

    class CatToy << Hash
      include CouchRest::Model::CastedModel

      property :name, String
      property :purchased, Date
    end

    class Cat << CouchRest::Model::Base
      property :name, String
      property :toys, [CatToy]
    end

    @cat = Cat.new(:name => 'Felix', :toys => [{:name => 'mouse', :purchases => 1.month.ago}])
    @cat.toys.first.class == CatToy
    @cat.toys.first.name == 'mouse'

Additionally, any hashes sent to the property will automatically be converted:

    @cat.toys << {:name => 'catnip ball'}
    @cat.toys.last.is_a?(CatToy) # True!

Of course, to use your own classes they *must* be defined before the parent uses them otherwise 
Ruby will bring up a missing constant error. To avoid this, or if you have a really simple array of data
you'd like to model, the latest version of CouchRest Model (> 1.0.0) supports creating
anonymous classes:

    class Cat << CouchRest::Model::Base
      property :name, String

      property :toys do |toy|
        toy.property :name, String
        toy.property :rating, Integer
      end
    end

    @cat = Cat.new(:name => 'Felix', :toys => [{:name => 'mouse', :rating => 3}, {:name => 'catnip ball', :rating => 5}])
    @cat.toys.last.rating == 5
    @cat.toys.last.name == 'catnip ball'

Using this method of anonymous classes will *only* create arrays of objects.


## Assocations

Two types at the moment:

    belongs_to :person

    collection_of :tags

TODO: Document properly!



## Validations

CouchRest Model automatically includes the new ActiveModel validations, so they should work just as the traditional Rails
validations. For more details, please see the ActiveModel::Validations documentation.

CouchRest Model adds the possibility to check the uniqueness of attributes using the @validates_uniqueness_of@ class method, for example:

    class Person < CouchRest::Model::Base
      property :title, String
     
      validates_uniqueness_of :title
    end

The uniqueness validation creates a new view for the attribute or uses one that already exists.
Given that the uniqueness check performs a request to the database, it is also possible
to include a +:proxy+ parameter. This allows you to
call a method on the document and provide an alternate proxy object.

Examples:

    # Same as not including proxy:
    validates_uniqueness_of :title, :proxy => 'class'
    
    # Person#company.people provides a proxy object for people
    validates_uniqueness_of :title, :proxy => 'company.people'



## Notable Issues

CouchRest Model uses active_support for some of its internals. Ensure you have a stable active support gem installed 
or at least 3.0.0.beta4.

JSON gem versions 1.4.X are kown to cause problems with stack overflows and general badness. Version 1.2.4 appears to work fine.

## Ruby on Rails

CouchRest Model is compatible with rails and provides some ActiveRecord-like methods.

The CouchRest companion rails project 
[http://github.com/hpoydar/couchrest-rails](http://github.com/hpoydar/couchrest-rails) is great
for provided default connection details for your database. At the time of writting however it 
does not provide explicit support for CouchRest Model.

CouchRest Model and the original CouchRest ExtendedDocument do not share the same namespace, 
as such you should not have any problems using them both at the same time. This might
help with migrations.


### Rails 3.0

In your environment.rb file require the gem as follows:

    Rails::Initializer.run do |config|
      ....
      config.gem "couchrest_model"
      ....
    end

## Testing

The most complete documentation is the spec/ directory. To validate your
CouchRest install, from the project root directory run `rake`, or `autotest`
(requires RSpec and optionally ZenTest for autotest support).

## Docs

API: [http://rdoc.info/projects/couchrest/couchrest_model](http://rdoc.info/projects/couchrest/couchrest_model)

Check the wiki for documentation and examples [http://wiki.github.com/couchrest/couchrest](http://wiki.github.com/couchrest/couchrest)


## Contact

Please post bugs, suggestions and patches to the bug tracker at [http://github.com/couchrest/couchrest/issues](http://github.com/couchrest/couchrest/issues).

Follow us on Twitter: [http://twitter.com/couchrest](http://twitter.com/couchrest)

Also, check [http://twitter.com/#search?q=%23couchrest](http://twitter.com/#search?q=%23couchrest)

