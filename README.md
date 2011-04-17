# CouchRest Model: CouchDB, close to shiny metal with rounded edges

CouchRest Models adds additional functionality to the standard CouchRest Document class such as
setting properties, callbacks, typecasting, and validations.

Originally called ExtendedDocument, the new Model structure uses ActiveModel, part of Rails 3, 
for validations and callbacks.

If your project is still running Rails 2.3, you'll have to continue using ExtendedDocument as 
it is not possible to load ActiveModel into programs that do not use ActiveSupport 3.0.

CouchRest Model is only properly tested on CouchDB version 1.0 or newer.

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

## Useful links and extensions

Try some of these gems that add extra funcionality to couchrest_model:

* [memories](http://github.com/moonmaster9000/memories) - object versioning using attachments (Matt Parker)
* [couch_publish](http://github.com/moonmaster9000/couch_publish) - versioned state machine for draft and published documents (Matt Parker)
* [couch_photo](http://github.com/moonmaster9000/couch_photo) - attach images to documents with variations (Matt Parker)
* [copycouch](http://github.com/moonmaster9000/copycouch) - single document replication on documents (Matt Parker)
* [recloner](https://github.com/moonmaster9000/recloner) - clone documents easily (Matt Parker)

If you have an extension that you'd us to add to this list, please get in touch!
			   
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
can be set as if the model were a Hash, this funcionality is inherited from CouchRest Documents.

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

    @cat = Cat.new(:name => 'Felix', :toys => [{:name => 'mouse', :purchased => 1.month.ago}])
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

      property :toys do
        property :name, String
        property :rating, Integer
      end
    end

    @cat = Cat.new(:name => 'Felix', :toys => [{:name => 'mouse', :rating => 3}, {:name => 'catnip ball', :rating => 5}])
    @cat.toys.last.rating == 5
    @cat.toys.last.name == 'catnip ball'

Anonymous classes will *only* create arrays of objects. If you're more of the traditional type, a block parameter
can be provided allowing you to use this variable before each method call inside the anonymous class. This is useful
if you need to access variables outside of the block.

## Views

CouchDB views can be quite difficult to get grips with at first as they are quite different from what you'd expect with SQL queries in a normal Relational Database. Checkout some of the [CouchDB documentation on views](http://wiki.apache.org/couchdb/Introduction_to_CouchDB_views) to get to grips with the basics. The key is to remember that CouchDB will only generate indexes from which you can extract consecutive rows of data, filtering other than between two points in a data set is not possible.

CouchRest Model has great support for views, and since version 1.1.0 we added support for a View objects that make accessing your data even easier. 

### The Old Way

Here's an example of adding a view to our Cat class:

    class Cat < CouchRest::Model::Base
      property :name, String
      property :toys, [CatToy]

      view_by :name
    end

The `view_by` method will create a view in the Cat's design document called "by_name". This will allow searches to be made for the Cat's name attribute. Calling `Cat.by_name` will send a query of to the database and return an array of all the Cat objects available. Internally, a map function is generated automatically and stored in CouchDB's design document for the current model, it'll look something like the following:

    function(doc) {
      if (doc['couchrest-type'] == 'Cat' && doc['name']) {
        emit(doc.name, null);
      }
    }

By default, a special view called `all` is created and added to all couchrest models that allows you access to all the documents in the database that match the model. By default, these will be ordered by each documents id field.

It is also possible to create views of multiple keys, for example:

    view_by :birthday, :name

This will create an view of all the cats' birthdays and their names called `by_birthday_and_name`.

Sometimes the automatically generate map function might not be sufficient for more complicated queries. To customize, add the :map and :reduce functions when creating the view:

    view_by :tags,
      :map =>
        "function(doc) {
          if (doc['model'] == 'Post' && doc.tags) {
            doc.tags.forEach(function(tag){
              emit(doc.tag, 1);
            });
          }
        }",
      :reduce =>
        "function(keys, values, rereduce) {
          return sum(values);
        }"

Calling a view will return document objects by default, to get access to the raw CouchDB result add the `:raw => true` option to get a hash instead. Custom views can also be queried with `:reduce => true` to return reduce results. The default is to query with `:reduce => false`.
 
Views are generated (on a per-model basis) lazily on first-access. This means that if you are deploying changes to a view, the views for
that model won't be available until generation is complete. This can take some time with large databases. Strategies are in the works.

### View Objects

Since CouchRest Model 1.1.0 it is now possible to create views that return objects chainable objects, similar to those you'd find in the Sequel Ruby library or Rails 3's Arel. Heres an example of creating a few views:

    class Post < CouchRest::Model::Base
      property :title
      property :body
      property :posted_at, DateTime
      property :tags, [String]

      design do
        view :by_title
        view :by_posted_at_and_title
        view :tag_list,
          :map =>
            "function(doc) {
              if (doc['model'] == 'Post' && doc.tags) {
                doc.tags.forEach(function(tag){
                  emit(doc.tag, 1);
                });
              }
            }",
          :reduce =>
            "function(keys, values, rereduce) {
              return sum(values);
            }"
      end

You'll see that this new syntax requires all views to be defined inside a design block. Unlike the old version, the keys to be used in a query are determined from the name of the view, not the other way round. Acessing data is the fun part:

    # Prepare a query:
    view = Post.by_posted_at_and_title.skip(5).limit(10)

    # Fetch the results:
    view.each do |post|
      puts "Title: #{post.title}"
    end

    # Grab the CouchDB result information with the same object:
    view.total_rows   => 10
    view.offset       => 5

    # Re-use and add new filters
    filter = view.startkey([1.month.ago]).endkey([Date.current, {}])

    # Fetch row results without the documents:
    filter.rows.each do |row|
      puts "Row value: #{row.value} Doc ID: #{row.id}"
    end

    # Lazily load documents (take last row from previous example):
    row.doc      => Fetch last Post document from database

    # Using reduced queries is also easy:
    tag_usage = Post.tag_list.reduce.group_level(1)
    tag_usage.rows.each do |row|
      puts "Tag: #{row.key}  Uses: #{row.value}"
    end

#### Pagination

The view objects have built in support for pagination based on the [kaminari](https://github.com/amatsuda/kaminari) gem. Methods are provided to match those required by the library to peform pagination.

For your view to support paginating the results, it must use a reduce function that provides a total count of the documents in the result set. By default, auto-generated views include a reduce function that supports this.

Use pagination as follows:

    # Prepare a query:
    @posts = Post.by_title.page(params[:page]).per(10)
    
    # In your view, with the kaminari gem loaded:
    paginate @posts

### Design Documents and Views

Views must be defined in a Design Document for CouchDB to be able to perform searches. Each model therefore must have its own Design Document. Deciding when to update the model's design doc is a difficult issue, as in production you don't want to be constantly checking for updates and in development maximum flexability is important. CouchRest Model solves this issue by providing the `auto_update_design_doc` configuration option and is enabled by default.

Each time a view or other design method is requested a quick GET for the design will be sent to ensure it is up to date with the latest changes. Results are cached in the current thread for the complete design document's URL, including the database, to try and limit requests. This should be fine for most projects, but dealing with multiple sub-databases may require a different strategy.

Setting the option to false will require a manual update of each model's design doc whenever you know a change has happened. This will be useful in cases when you do not want CouchRest Model to interfere with the views already store in the CouchRest database, or you'd like to deploy your own update strategy. Here's an example of a module that will update all submodules:

    module CouchRestMigration
      def self.update_design_docs
        CouchRest::Model::Base.subclasses.each{|klass| klass.save_design_doc! if klass.respond_to?(:save_design_doc!)}
      end
    end

    # Running this from your applications initializers would be a good idea,
    # for example in Rail's application.rb or environments/production.rb:
    config.after_initialize do
      CouchRestMigration.update_design_docs
    end

If you're dealing with multiple databases, using proxied models, or databases that are created on-the-fly, a more sophisticated approach might be required:

    module CouchRestMigration
      def self.update_all_design_docs
        update_design_docs(COUCHREST_DATABASE)
        Company.all.each do |company|
          update_design_docs(company.proxy_database)
        end
      end
      def self.update_design_docs(db)
        CouchRest::Model::Base.subclasses.each{|klass| klass.save_design_doc!(db) if klass.respond_to?(:save_design_doc!(db)}
      end
    end

    # Command to run after a capistrano migration:
    $ rails runner "CouchRestMigratin.update_all_design_docs"


## Assocations

Two types at the moment:

    belongs_to :person

    collection_of :tags

This is a somewhat controvesial feature of CouchRest Model that some document database purists may cringe at. CouchDB does not yet povide many features to support relationships between documents but the fact of that matter is that its a very useful paradigm for modelling data systems.

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

## Proxy Support

CouchDB makes it really easy to create databases on the fly, so easy in fact that it is perfectly
feasable to have one database per user or per company or per whatever makes sense to split into
its own individual database. CouchRest Model now makes it really easy to support this scenario
using the proxy methods. Here's a quick example:

    # Define a master company class, its children should be in their own DB
    class Company < CouchRest::Model::Base
      use_database COUCHDB_DATABASE
      property :name
      property :slug

      proxy_for :invoices

      def proxy_database
        @proxy_database ||= COUCHDB_SERVER.database!("project_#{slug}")
      end
    end

    # Invoices belong to a company
    class Invoice < CouchRest::Model::Base
      property :date
      property :total

      proxied_by :company

      design do
        view :by_date
      end
    end

By setting up our models like this, the invoices should be accessed via a company object:

    company = Company.first
    company.invoices.new            # build a new invoice
    company.invoices.by_date.first  # find company's first invoice by date

Internally, all requests for invoices are passed through a model proxy. Aside from the 
basic methods and views, it also ensures that some of the more complex queries are supported
such as validating for uniqueness and associations.


## Configuration

CouchRest Model supports a few configuration options. These can be set either for the whole Model code
base or for a specific model of your chosing. To configure globally, provide something similar to the 
following in your projects initializers or environments:

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
 * `auto_update_design_doc` - true by default, every time a view is requested and this option is enabled, a quick check will be performed to ensure the model's design document is up to date. When disabled, you'll need to perform the updates manually. Typically, this option should be enabled in development, and disabled in production. See the View section for more details.


## Notable Issues

None at the moment...


## Testing

The most complete documentation is the spec/ directory. To validate your CouchRest install, from the project root directory run `rake`, or `autotest` (requires RSpec and optionally ZenTest for autotest support).

## Docs

API: [http://rdoc.info/projects/couchrest/couchrest_model](http://rdoc.info/projects/couchrest/couchrest_model)

Check the wiki for documentation and examples [http://wiki.github.com/couchrest/couchrest_model](http://wiki.github.com/couchrest/couchrest_model)


## Contact

Please post bugs, suggestions and patches to the bug tracker at [http://github.com/couchrest/couchrest_model/issues](http://github.com/couchrest/couchrest_model/issues).

Follow us on Twitter: [http://twitter.com/couchrest](http://twitter.com/couchrest)

Also, check [http://twitter.com/#search?q=%23couchrest](http://twitter.com/#search?q=%23couchrest)

