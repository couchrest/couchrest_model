class SaleEntry < CouchRest::Model::Base
  use_database DB

  property :description
  property :price

  design do
    view :by_description
  end
  
end
