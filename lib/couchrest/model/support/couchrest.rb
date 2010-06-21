
module CouchRest

  class Database

    alias :delete_orig! :delete!
    def delete!
      clear_model_fresh_cache
      delete_orig!
    end

    # If the database is deleted, ensure that the design docs will be refreshed.
    def clear_model_fresh_cache
      ::CouchRest::Model::Base.subclasses.each{|klass| klass.req_design_doc_refresh if klass.respond_to?(:req_design_doc_refresh)}
    end

  end

end
