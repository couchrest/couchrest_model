class Person < Hash
  include ::CouchRest::CastedModel
  property :pet, :cast_as => 'Cat'
  property :name, [String]
  
  def last_name
    name.last
  end
end
