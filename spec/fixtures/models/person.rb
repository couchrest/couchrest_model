require 'cat'

class Person < Hash
  include ::CouchRest::Model::CastedModel
  property :pet, Cat
  property :name, [String]
  
  def last_name
    name.last
  end
end
