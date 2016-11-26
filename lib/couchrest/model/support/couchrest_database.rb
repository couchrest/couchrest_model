#
# Extend CouchRest's normal database delete! method to ensure any caches are
# also emptied. Given that this is a rare event, and the consequences are not 
# very severe, we just completely empty the cache.
#
module CouchRest::Model
  module Support
    module Database

      def delete!
        Thread.current[:couchrest_design_cache] = { }
        super
      end

    end
  end
end

class CouchRest::Database
  prepend CouchRest::Model::Support::Database
end
