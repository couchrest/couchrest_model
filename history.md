# CouchRest Model Change History

## 2.0.2 - pending

  * Fix for model_type_value, not being used correctly from database.

## 2.0.1 - 2013-12-03

  * nil keys in view requests are now sent to server, avoiding returning first document issue. (Thanks to @svoboda-jan for pointer.)
  * lazy create database if using `use_database`
  * added .model_type_value to persistence layer, so that model name can be overwrriten if required (issue #163)

## 2.0.0 - 2013-10-04

  * Added design doc migration support, including for proxied models
  * Rake tasks available for migrations
  * Rails config option now available: `config.couchrest_model.auto_update_design_docs = false`
  * Skipping 1.2 version due to design doc API changes
  * Added 'couchrest_typecast' class method support for typecasting with special classes.
  * Added :allow_blank option to properties so that empty strings are forced to nil.
  * Modified associations to use allow_blank property
  * Incorported Rails 3.2 support changes (Thanks @jodosha)
  * Kaminari support upgraded to use 0.14.0 API (Thanks @amatsuda)
  * JSON Oj support, fixed some Time handling issues
  * Simplifying number typecasting to always provide a number, or nil.
  * Reduce option in views now accepts symbols: `:sum` to `'_sum'`
  * Dirty tracking now supports CastedArray#insert method.
  * Support for Rails 4.0.
  * Removing support for <= Ruby 1.9.2.
  * Fixing model translation support.
  * Fixing `belongs_to` setting foreign key cache issue.
  * Support typecasting `Symbol`
  * Added `:array` option to properties
  * Typecasting Dates, Times, and Booleans, with invalid values returns nil
  
  * API Breaking Changes
    * Properties with blocks are now singular unless the `array: true` option is passed.
  

## 1.2.0.beta - 2012-06-08

  * Completely refactored Design Document handling.
  * Removed old `view` and `view_by` methods.
  * CouchRest::Model::Base.respond_to_missing? and respond_to? (Kim Burgestrand) (later removed)
  * Time#as_json now insists on using xmlschema with 3 fraction digits by default.
  * Added time_fraction_digits configuration object

## 1.1.2 - 2011-07-23

* Minor fixes
  * Upgrade to couchrest 1.1.2
  * Override as_couch_json to ensure nil values not stored
  * Removing restriction that prohibited objects that cast as an array to be loaded.

## 1.1.1 - 2011-07-04

* Minor fix
  * Bumping CouchRest version dependency for important initialize method fix.
  * Ensuring super on Embeddable#initialize can be called.

## 1.1.0 - 2011-06-25

* Major Alterations
  * CastedModel no longer requires a Hash. Automatically includes all required methods.
  * CastedModel module renamed to Embeddable (old still works!)

* Minor Fixes
  * Validation callbacks now support context (thanks kostia)
  * Document comparisons now performed using database and document ID (pointer by neocsr)
  * Automatic config generation now supported (thanks lucasrenan)
  * Comparing documents resorts to Hash comparison if both IDs are nil. (pointer by kostia)

## 1.1.0.rc1 - 2011-06-08

* New Features
  * Properties with a nil value are now no longer sent to the database.
  * Now possible to build new objects via CastedArray#build
  * Implement #get! and #find! class methods
  * Now is possible delete particular elements in casted array(Kostiantyn Kahanskyi)

* Minor fixes
  * #as_json now correctly uses ActiveSupports methods.
  * Rails 3.1 support (Peter Williams)
  * Initialization blocks when creating new models (Peter Williams)
  * Removed railties dependency (DAddYE)
  * DesignDoc cache refreshed if a database is deleted.
  * Fixing dirty tracking on collection_of association.
  * Uniqueness Validation views created on initialization, not on demand!
  * #destroy freezes object instead of removing _id and _rev, better for callbacks (pointer by karmi)
  * #destroyed? method now available
  * #reload no longer uses Hash#merge! which was causing issues with dirty tracking on casted models. (pointer by kostia)
  * Non-property mass assignment on #new no longer possible without :directly_set_attributes option.
  * Using CouchRest 1.1.0.pre3. (No more Hashes!)
  * Fixing problem assigning a CastedHash to a property declared as a Hash (Kostiantyn Kahanskyi, gfmtim)

## 1.1.0.beta5 - 2011-04-30

* Major changes:
  * Database auto configuration, with connection options!
  * Changed default CouchRest Model type to 'type' to be more consistent with ActiveRecord's reserverd words we're all used to (sorry for the change again!!)

* Minor changes
  * Added filter option to designs (Used with CouchDB _changes feeds)

## 1.1.0.beta4

* Major changes:
  * Fast Dirty Tracking! Many thanks to @sobakasu (Andrew Williams)
  * Default CouchRest Model type field now set to 'model' instead of 'couchrest-type'.

* Minor enhancements:
  * Adding "couchrest-hash" to Design Docs with aim to improve view update handling.
  * Major changes to the way design document updates are handled internally.
  * Added "auto_update_design_doc" configuration option.
  * Using #descending on View object will automatically swap startkey with endkey.

## 1.1.0.beta3

* Removed

## 1.1.0.beta2

* Minor enhancements:
  * Time handling improved in accordance with CouchRest 1.1.0. Always set to UTC.
  * Refinements to associations and uniqueness validation for proxy (based on issue found by Gleb Kanterov)
  * Added :allow_nil and :allow_blank options when creating a new view
  * Unique Validation now supports scopes!
  * Added support for #keys with list on Design View.

## 1.1.0.beta

* Epic enhancements:
  * Added "View" object for dynamic view queries
  * Added easy to use proxy_for and proxied_by class methods for proxying data

* Minor enhancements:
  * A yield parameter in an anonymous casted model property block is no longer required (@samlown)
  * Narrow the rescued exception to avoid catching class evaluation errors that has nothing to to with the association (thanks Simone Carletti)
  * Fix validate uniqueness test that was never executed (thanks Simone Carletti)
  * Adds a #reload method to reload document attributes (thanks Simone Carletti)
  * Numeric types can be casted from strings with leading or trailing whitespace (thanks chrisdurtschi)
  * CollectionProxy no longer provided by default with simple views (pending deprication)

## CouchRest Model 1.0.0

* Major enhancements
  * Support for configuration module and "model_type_key" option for overriding model's type key
  * Added "mass_assign_any_attribute" configuration option to allow setting anything via the attribute= method.

* Minor enhancements
  * Fixing find("") issue (thanks epochwolf)
  * Altered protected attributes so that hash provided to #attributes= is not modified
  * Altering typecasting for floats to better handle commas and points
  * Fixing the lame pagination bug where database url (and pass!!) were included in view requests (Thanks James Hayton)

Notes:

* 2010-10-22 @samlown:
  * ActiveModel Attribute support was added but has now been removed due to major performance issues.
  Until these have been resolved (if possible?!) they should not be included. See the
  'active_model_attrs' if you'd like to test.

## CouchRest Model 1.0.0.beta8

* Major enhancements
	* Added model generator

* Minor enhancements
  * Raise error on adding objects to "collection_of" without an id
  * Allow mixing of protected and accessible properties. Any unspecified properties are now assumed to be protected by default
  * Parsing times without zone
  * Using latest rspec (2.0.0.beta.19)

## CouchRest Model 1.0.0.beta7

* Major enhancements
  * Renamed ExtendedDocument to CouchRest::Model
  * Added initial support for simple belongs_to associations
  * Added support for basic collection_of association (unique to document databases!)
  * Moved Validation to ActiveModel
  * Moved Callbacks to ActiveModel
  * Removed support for properties defined using a string for the type instead of a class
  * Validation always included
  * Uniqueness validation now available

* Minor enhancements
  * Removed support for auto_validate! and :length on properties


## 1.0.0.beta6

* Major enhancements
  * Added support for anonymous CastedModels defined in Documents

* Minor enhancements
  * Added 'find_by_*' alias for finding first item in view with matching key.
  * Fixed issue with active_support in Rails3 and text in README for JSON.
  * Refactoring of properties, added read_attribute and write_attribute methods.
  * Now possible to send anything to update_attribtues method. Invalid or readonly attributes will be ignored.
  * Attributes with arrays are *always* instantiated as a CastedArray.
  * Setting a property of type Array (or keyed hash) must be an array or an error will be raised.
  * Now possible to set Array attribute from hash where keys determine order.

## 1.0.0.beta5

* Minor enhancements
  * Added 'find' alias for 'get' for easier rails transition

## 1.0.0.beta3

* Minor enhancements
  * Removed Validation by default, requires too many structure changes (FAIL)
  * Added support for instantiation of documents read from database as couchrest-type provided (Sam Lown)
  * Improved attachment handling for detecting file type (Sam Lown)
  * Removing some monkey patches and relying on active_support for constantize and humanize (Sam Lown)
  * Added support for setting type directly on property (Sam Lown)


## 1.0.0.beta2

* Minor enhancements
  * Enable Validation by default and refactored location (Sam Lown)

## 1.0.0.beta

* Major enhancements
  * Separated ExtendedDocument from main CouchRest gem (Sam Lown)

* Minor enhancements
  * active_support included by default

## 0.37

* Minor enhancements
  * Added gemspec (needed for Bundler install) (Tapajós)

## 0.36

* Major enhancements
  * Adds support for continuous replication (sauy7)
  * Automatic Type Casting (Alexander Uvarov, Sam Lown, Tim Heighes, Will Leinweber)
  * Added a search method to CouchRest:Database to search the documents in a given database. (Dave Farkas, Arnaud Berthomier, John Wood)

* Minor enhancements
  * Provide a description of the timeout error (John Wood)

## 0.35

* Major enhancements
  * CouchRest::ExtendedDocument allow chaining the inherit class callback (Kenneth Kalmer) - http://github.com/couchrest/couchrest/issues#issue/8

* Minor enhancements
  * Fix attachment bug (Johannes Jörg Schmidt)
  * Fix create database exception bug (Damien Mathieu)
  * Compatible with restclient >= 1.4.0 new responses (Julien Kirch)
  * Bug fix: Attribute protection no longer strips attributes coming from the database (Will Leinweber)
  * Bug fix: Remove double CGI escape when PUTting an attachment (nzoschke)
  * Bug fix: Changing Class proxy to set database on result sets (Peter Gumeson)
  * Bug fix: Updated time regexp (Nolan Darilek)
  * Added an update_doc method to database to handle conflicts during atomic updates. (Pierre Larochelle)
  * Bug fix: http://github.com/couchrest/couchrest/issues/#issue/2 (Luke Burton)

## 0.34

* Major enhancements

  * Added support for https database URIs. (Mathias Meyer)
  * Changing some validations to be compatible with activemodel. (Marcos Tapajós)
  * Adds attribute protection to properties. (Will Leinweber)
  * Improved CouchRest::Database#save_doc, added "batch" mode to significantly speed up saves at cost of lower durability gurantees. (Igal Koshevoy)
  * Added CouchRest::Database#bulk_save_doc and #batch_save_doc as human-friendlier wrappers around #save_doc. (Igal Koshevoy)

* Minor enhancements

  * Fix content_type handling for attachments
  * Fixed a bug in the pagination code that caused it to paginate over records outside of the scope of the view parameters.(John Wood)
  * Removed amount_pages calculation for the pagination collection, since it cannot be reliably calculated without a view.(John Wood)
  * Bug fix: http://github.com/couchrest/couchrest/issues/#issue/2 (Luke Burton)
  * Bug fix: http://github.com/couchrest/couchrest/issues/#issue/1 (Marcos Tapajós)
  * Removed the Database class deprecation notices (Matt Aimonetti)
  * Adding support to :cast_as => 'Date'.  (Marcos Tapajós)
  * Improve documentation  (Marcos Tapajós)
  * Streamer fixes (Julien Sanchez)
  * Fix Save on Document & ExtendedDocument crashed if bulk (Julien Sanchez)
  * Fix Initialization of ExtendentDocument model shouldn't failed on a nil value in argument (deepj)
  * Change to use Jeweler and Gemcutter (Marcos Tapajós)

## 0.33

* Major enhancements

  * Added a new Rack logger middleware letting you log/save requests/queries (Matt Aimonetti)

* Minor enhancements

  * Added #amount_pages to a paginated result array (Matt Aimonetti)
  * Ruby 1.9.2 compatible (Matt Aimonetti)
  * Added a property? method for property cast as :boolean (John Wood)
  * Added an option to force the deletion of a attachments (bypass 409s) (Matt Aimonetti)
  * Created a new abstraction layer for the REST API (Matt Aimonetti)
  * Bug fix: made ExtendedDocument#all compatible with Couch 0.10 (tc)

## 0.32

* Major enhancements

  * ExtendedDocument.get doesn't raise an exception anymore. If no documents are found nil is returned.
  * ExtendedDocument.get! works the say #get used to work and will raise an exception if a document isn't found.

* Minor enhancements

  * Bug fix: Model.all(:keys => [1,2]) was not working (Matt Aimonetti)
  * Added ValidationErrors#count in order to play nicely with Rails (Peter Wagenet)
  * Bug fix: class proxy design doc refresh (Daniel Kirsh)
  * Bug fix: the count method on the proxy collection was missing (Daniel Kirsch)
  * Added #amount_pages to a paginated collection. (Matt Aimonetti)

## 0.31

* Major enhancements

  * Created an abstraction HTTP layer to support different http adapters (Matt Aimonetti)
  * Added ExtendedDocument.create({}) and #create!({}) so you don't have to do Model.new.create (Matt Aimonetti)

* Minor enhancements

  * Added an init.rb file for easy usage as a Rails plugin (Aaron Quint)
  * Bug fix: pagination shouldn't die on empty results (Arnaud Berthomier)
  * Optimized ExtendedDocument.count to run about 3x faster (Matt Aimonetti)
  * Added Float casting (Ryan Felton & Matt Aimonetti)

## 0.30

* Major enhancements

  * Added support for pagination (John Wood)
  * Improved performance when initializing documents with timestamps (Matt Aimonetti)

* Minor enhancements

  * Extended the API to retrieve an attachment URI (Matt Aimonetti)
  * Bug fix: default value should be able to be set as false (Alexander Uvarov)
  * Bug fix: validates_is_numeric should be able to properly validate a Float instance (Rob Kaufman)
  * Bug fix: fixed the Timeout implementation (Seth Falcon)


---

Unfortunately, before 0.30 we did not keep a track of the modifications made to CouchRest.
You can see the full commit history on GitHub: http://github.com/couchrest/couchrest/commits/master/
