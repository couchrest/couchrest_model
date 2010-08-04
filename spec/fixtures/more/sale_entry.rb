class SaleEntry < CouchRest::Model::Base
  use_database DB

  property :description
  property :price
  
  view_by :description
  
end