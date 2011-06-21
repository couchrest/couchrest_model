class Question < Hash
  include ::CouchRest::Model::CastedModel
  
  property :q
  property :a

end
