
module CouchRest

  class Database

    alias :delete_old! :delete!
    def delete!
      clear_extended_doc_fresh_cache
      delete_old!
    end

    # If the database is deleted, ensure that the design docs will be refreshed.
    def clear_extended_doc_fresh_cache
      ::CouchRest::ExtendedDocument.subclasses.each{|klass| klass.req_design_doc_refresh if klass.respond_to?(:req_design_doc_refresh)}
    end

  end

end
