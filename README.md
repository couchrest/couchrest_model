# CouchRest::ExtendedDocument: CouchDB, not too close to the metal

CouchRest::ExtendedDocument adds additional functionality to the standard CouchRest Document class such as
setting properties, callbacks, typecasting, and validations.

Note: CouchRest::ExtendedDocument only supports CouchDB 0.10.0 or newer.

## Install

    $ sudo gem install couchrest_extended_document
   
## Usage

### General   

    require 'couchrest_extended_document'

    class Cat < CouchRest::ExtendedDocument

      property :name,      String
      property :lives,     Integer, :default => 9

      property :nicknames, [String]

      timestamps!

      view_by :name

    end

### Ruby on Rails

CouchRest::ExtendedDocument is compatible with rails and provides some ActiveRecord-like methods.
You might also be interested in the CouchRest companion rails project:
[http://github.com/hpoydar/couchrest-rails](http://github.com/hpoydar/couchrest-rails)      

#### Rails 2.X

In your environment.rb file require the gem as follows:

    Rails::Initializer.run do |config|
      ....
      config.gem "couchrest_extended_document"
      ....
    end

## Testing

The most complete documentation is the spec/ directory. To validate your
CouchRest install, from the project root directory run `rake`, or `autotest`
(requires RSpec and optionally ZenTest for autotest support).

## Docs

API: [http://rdoc.info/projects/couchrest/couchrest_extended_document](http://rdoc.info/projects/couchrest/couchrest_extended_document)

Check the wiki for documentation and examples [http://wiki.github.com/couchrest/couchrest](http://wiki.github.com/couchrest/couchrest)



## Contact

Please post bugs, suggestions and patches to the bug tracker at [http://github.com/couchrest/couchrest/issues](http://github.com/couchrest/couchrest/issues).

Follow us on Twitter: [http://twitter.com/couchrest](http://twitter.com/couchrest)

Also, check [http://twitter.com/#search?q=%23couchrest](http://twitter.com/#search?q=%23couchrest)

