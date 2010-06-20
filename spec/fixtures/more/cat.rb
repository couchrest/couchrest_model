
class CatToy < Hash
  include ::CouchRest::Model::CastedModel

  property :name

  validates_presence_of :name
end

class Cat < CouchRest::Model::Base
  # Set the default database to use
  use_database DB

  property :name, :accessible => true
  property :toys, [CatToy], :default => [], :accessible => true
  property :favorite_toy, CatToy, :accessible => true
  property :number
end

