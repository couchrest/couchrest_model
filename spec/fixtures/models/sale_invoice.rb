require 'client'
require 'sale_entry'

class SaleInvoice < CouchRest::Model::Base
  use_database DB

  belongs_to :client
  belongs_to :alternate_client, :class_name => 'Client', :foreign_key => 'alt_client_id'

  collection_of :entries, :class_name => 'SaleEntry'

  property :date, Date
  property :price, Integer 
end
