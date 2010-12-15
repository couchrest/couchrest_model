# CouchRest Model: CouchDB, close to shiny metal with rounded edges

CouchRest Models adds additional functionality to the standard CouchRest Document class such as
setting properties, callbacks, typecasting, and validations.

Originally called ExtendedDocument, the new Model structure uses ActiveModel, part of Rails 3, 
for validations and callbacks.

If your project is still running Rails 2.3, you'll have to continue using ExtendedDocument as 
it is not possible to load ActiveModel into programs that do not use ActiveSupport 3.0.

CouchRest Model is only tested on CouchDB 1.0.0 or newer.

## Install

### Gem

    $ sudo gem install couchrest_model

### Bundler

If you're using bundler, just define a line similar to the following in your project's Gemfile:

    gem 'couchrest_model'

You might also consider using the latest git repository. All tests should pass in the master code branch
but no guarantees!

    gem 'couchrest_model', :git => 'git://github.com/couchrest/couchrest_model.git'

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


## Properties

A property is the definition of an attribute, it describes what the attribute is called, how it should
be type casted and other options such as the default value. These replace your typical 
`add_column` methods found in relational database migrations.

Attributes with a property definition will have setter and getter methods defined for them. Any other attibute
can be set in the same way you'd update a Hash, this funcionality is inherited from CouchRest Documents.

Here are a few examples of the way properties are used:

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

Properties can also have a type which will be used for casting data retrieved from CouchDB when the attribute is set:

    class Cat < CouchRest::Model::Base
      property :name, String
      property :last_fed_at, Time
    end

    @cat = Cat.new(:name => 'Felix', :last_fed_at => 10.minutes.ago)
    @cat.last_fed_at.is_a?(Time)   # True!
    @cat.save
    @cat = Cat.find(@cat.id)
    @cat.last_fed_at < 20.minutes.ago   # True!


Boolean or TrueClass types will create a getter with question mark at the end:

    class Cat < CouchRest::Model::Base
      property :awake, TrueClass, :default => true
    end

    @cat.awake?   # true

Adding the +:default+ option will ensure the attribute always has a value.

A read-only property will only have a getter method, and its value is set when the document
is read from the database. You can however update a read-only attribute using the `write_attribute` method:

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

Mass assigning attributes is also possible in a similar fashion to ActiveRecord:

    @cat.attributes = { :name => "Felix" }
    @cat.save

Is the same as:

    @cat.update_attributes(:name => "Felix")

By default, attributes without a property will not be updated via the `#attributes=` method. This provents useless data being passed to database, for example from an HTML form. However, if you would like truely
dynamic attributes, the `mass_assign_any_attribute` configuration option when set to true will 
store everything you put into the `Base#attributes=` method.


## Property Arrays

An attribute may contain an array of data. CouchRest Model handles this, along
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
into special wrapper called a CastedArray. If the child objects respond to the `casted_by` method
(such as those created with CastedModel, below) it will contain a reference to the parent.

## Casted Models

CouchRest Model allows you to take full advantage of CouchDB's ability to store complex 
documents and retrieve them using the CastedModel module. Simply include the module in
a Hash (or other model that responds to the [] and []= methods) and set any properties
you'd like to use. For example:

    class CatToy < Hash
      include CouchRest::Model::CastedModel

      property :name, String
      property :purchased, Date
    end

    class Cat < CouchRest::Model::Base
      property :name, String
      property :toys, [CatToy]
    end

    @cat = Cat.new(:name => 'Felix', :toys => [{:name => 'mouse', :purchases => 1.month.ago}])
    @cat.toys.first.class == CatToy
    @cat.toys.first.name == 'mouse'

Any hashes sent to the property will automatically be converted:

    @cat.toys << {:name => 'catnip ball'}
    @cat.toys.last.is_a?(CatToy) # True!

To use your own classes they *must* be defined before the parent uses them otherwise 
Ruby will bring up a missing constant error. To avoid this, or if you have a really simple array of data
you'd like to model, CouchRest Model supports creating anonymous classes:

    class Cat < CouchRest::Model::Base
      property :name, String

      property :toys do |toy|
        toy.property :name, String
        toy.property :rating, Integer
      end
    end

    @cat = Cat.new(:name => 'Felix', :toys => [{:name => 'mouse', :rating => 3}, {:name => 'catnip ball', :rating => 5}])
    @cat.toys.last.rating == 5
    @cat.toys.last.name == 'catnip ball'

Anonymous classes will *only* create arrays of objects.


## Assocations

Two types at the moment:

    belongs_to :person

    collection_of :tags

This is a somewhat controvesial feature of CouchRest Model that some document database purists may fringe at. CouchDB does not yet povide many features to support relationships between documents but the fact of that matter is that its a very useful paradigm for modelling data systems.

In the near future we hope to add support for a `has_many` relationship that takes of the _Linked Documents_ feature that arrived in CouchDB 0.11.

### Belongs To

Creates a property in the document with `_id` added to the end of the name of the foreign model with getter and setter methods to access the model. 

Example:

    class Cat < CouchRest::Model::Base
      belongs_to :mother
      property :name
    end

    kitty = Cat.new(:name => "Felix")
    kitty.mother = Mother.find_by_name('Sophie')

Providing a object to the setter, `mother` in the example will automagically update the `mother_id` attribute. Retrieving the data later is just as expected:

    kitty = Cat.find_by_name "Felix"
    kitty.mother.name == 'Sophie'

Belongs_to accepts a few options to add a bit more felxibility:

* `:class_name` - the camel case string name of the class used to load the model.
* `:foreign_key` - the name of the property to use instead of the attribute name with `_id` on the end.
* `:proxy` - a string that when evaluated provides a proxy model that responds to `#get`.

The last option, `:proxy` is a feature currently in testing that allows objects to be loaded from a proxy class, such as `ClassProxy`. For example:

    class Invoice < CouchRest::Model::Base
      attr_accessor :company
      belongs_to :project, :proxy => 'self.company.projects'
    end

A project instance in this scenario would need to be loaded by calling `#get(project_id)` on `self.company.projects` in the scope of an instance of the Invoice. We hope to document and work on this powerful feature in the near future.


### Collection Of

A collection_of relationship is much like belongs_to except that rather than just one foreign key, an array of foreign keys can be stored. This is one of the great features of a document database. This relationship uses a proxy object to automatically update two arrays; one containing the objects being used, and a second with the foreign keys used to the find them.

The best example of this in use is with Labels:

    class Invoice < CouchRest::Model::Base
      collection_of :labels
    end

    invoice = Invoice.new
    invoice.labels << Label.get('xyz')
    invoice.labels << Label.get('abc')

    invoice.labels.map{|l| l.name} # produces ['xyz', 'abc']

See the belongs_to relationship for the options that can be used. Note that this isn't especially efficient, a `get` is performed for each model in the array. As with a has_many relationship, we hope to be able to take advantage of the Linked Documents feature to avoid multiple requests.


## Validations

CouchRest Model automatically includes the new ActiveModel validations, so they should work just as the traditional Rails validations. For more details, please see the ActiveModel::Validations documentation.

CouchRest Model adds the possibility to check the uniqueness of attributes using the `validates_uniqueness_of` class method, for example:

    class Person < CouchRest::Model::Base
      property :title, String
     
      validates_uniqueness_of :title
    end

The uniqueness validation creates a new view for the attribute or uses one that already exists. You can
specify a different view using the `:view` option, useful for when the `unique_id` is specified and
you'd like to avoid the typical RestClient Conflict error:

    unique_id :code
    validates_uniqueness_of :code, :view => 'all'

Given that the uniqueness check performs a request to the database, it is also possible to include a `:proxy` parameter. This allows you to call a method on the document and provide an alternate proxy object.

Examples:

    # Same as not including proxy:
    validates_uniqueness_of :title, :proxy => 'class'
    
    # Person#company.people provides a proxy object for people
    validates_uniqueness_of :title, :proxy => 'company.people'


A really interesting use of `:proxy` and `:view` together could be where you'd like to ensure the ID is unique between several types of document. For example:

    class Product < CouchRest::Model::Base
      property :code

      validates_uniqueness_of :code, :view => 'by_product_code'

      view_by :product_code, :map => "
        function(doc) {
          if (doc['couchrest-type'] == 'Product' || doc['couchrest-type'] == 'Project') {
            emit(doc['code']);
          }
        }
      "
    end

    class Project < CouchRest::Model::Base
      property :code

      validates_uniqueness_of :code, :view => 'by_product_code', :proxy => 'Product'
    end

Pretty cool!


## Configuration

CouchRest Model supports a few configuration options. These can be set either for the whole Model code
base or for a specific model of your chosing. To configure globally, provide something similar to the 
following in your projects loading code:

    CouchRest::Model::Base.configure do |config|
      config.mass_assign_any_attribute = true
      config.model_type_key = 'couchrest-type'
    end

To set for a specific model:

   class Cat < CouchRest::Model::Base
     mass_assign_any_attribute true
   end

Options currently avilable are:

 * `mass_assign_any_attribute` - false by default, when true any attribute may be updated via the update_attributes or attributes= methods.
 * `model_type_key` - 'couchrest-type' by default, is the name of property that holds the class name of each CouchRest Model.


## Notable Issues

None at the moment...


## Ruby on Rails

CouchRest Model is compatible with rails and provides some ActiveRecord-like methods.

The CouchRest companion rails project [http://github.com/hpoydar/couchrest-rails](http://github.com/hpoydar/couchrest-rails) is great for providing default connection details for your database. At the time of writting however it does not provide explicit support for CouchRest Model.

CouchRest Model and the original CouchRest ExtendedDocument do not share the same namespace, as such you should not have any problems using them both at the same time. This might help with migrations.


## Testing

The most complete documentation is the spec/ directory. To validate your CouchRest install, from the project root directory run `rake`, or `autotest` (requires RSpec and optionally ZenTest for autotest support).

## Docs

API: [http://rdoc.info/projects/couchrest/couchrest_model](http://rdoc.info/projects/couchrest/couchrest_model)

Check the wiki for documentation and examples [http://wiki.github.com/couchrest/couchrest_model](http://wiki.github.com/couchrest/couchrest_model)


## Contact

Please post bugs, suggestions and patches to the bug tracker at [http://github.com/couchrest/couchrest_model/issues](http://github.com/couchrest/couchrest_model/issues).

Follow us on Twitter: [http://twitter.com/couchrest](http://twitter.com/couchrest)

Also, check [http://twitter.com/#search?q=%23couchrest](http://twitter.com/#search?q=%23couchrest)

