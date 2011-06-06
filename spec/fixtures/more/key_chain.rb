class KeyChain < CouchRest::Model::Base
  use_database(DB)

  property(:keys, Hash)
end
