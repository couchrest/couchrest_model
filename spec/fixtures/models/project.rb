class Project < CouchRest::Model::Base
  use_database DB

  disable_dirty_tracking true

  property :name,   String
  timestamps!

  design do
    view :by_name
  end
end
