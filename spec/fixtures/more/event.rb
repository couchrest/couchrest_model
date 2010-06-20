class Event < CouchRest::Model::Base
  use_database DB
  
  property :subject
  property :occurs_at, Time, :init_method => 'parse'
  property :end_date, Date, :init_method => 'parse'
  
end
