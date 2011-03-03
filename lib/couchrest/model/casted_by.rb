
module CouchRest::Model
  module CastedBy
    extend ActiveSupport::Concern
    included do
      self.send(:attr_accessor, :casted_by)
    end

    # Gets a reference to the actual document in the DB
    # Calls up to the next document if there is one,
    # Otherwise we're at the top and we return self
    def base_doc
      return self if base_doc?
      @casted_by ? @casted_by.base_doc : nil
    end

    # Checks if we're the top document
    def base_doc?
      false
    end

  end
end
