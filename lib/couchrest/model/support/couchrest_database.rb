#
# Extend CouchRest's normal database delete! method to ensure any caches are
# also emptied. Given that this is a rare event, and the consequences are not 
# very severe, we just completely empty the cache.
#
CouchRest::Database.class_eval do

  def delete!
    Thread.current[:couchrest_design_cache] = { }
    CouchRest.delete @root
  end

end
