class Project < CouchRest::Model::Base
  use_database DB
  property :name,   String
  timestamps!

  design do
    view :by_name
  end
end
