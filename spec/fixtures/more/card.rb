class Card < CouchRest::Model::Base 
  # Set the default database to use
  use_database DB
  
  # Official Schema
  property :first_name
  property :last_name,        :alias     => :family_name
  property :read_only_value,  :read_only => true
  property :cast_alias,       Person,  :alias  => :calias

  
  timestamps!
  
  # Validation
  validates_presence_of :first_name
  
end
