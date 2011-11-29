class Service < CouchRest::Model::Base
  # Set the default database to use
  use_database DB
  
  # Official Schema
  property :name
  property :price, Integer
  
  validates_length_of :name, :minimum => 4, :maximum => 20
end
