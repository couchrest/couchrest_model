
module CouchRest::Model
  module CastedBy
    extend ActiveSupport::Concern
    included do
      self.send(:attr_accessor, :casted_by)
      self.send(:attr_accessor, :casted_by_property)
    end

    # Gets a reference to the actual document in the DB
    # Calls up to the next document if there is one,
    # Otherwise we're at the top and we return self
    def base_doc
      return self if base_doc?
      casted_by ? casted_by.base_doc : nil
    end

    # Checks if we're the top document
    def base_doc?
      !casted_by
    end

    # Provide the property this casted model instance has been
    # used by. If it has not been set, search through the 
    # casted_by objects properties to try and find it.
    #def casted_by_property
    #  return nil unless casted_by
    #  attrs = casted_by.attributes
    #  @casted_by_property ||= casted_by.properties.detect{ |k| attrs[k.to_s] === self }
    #end

  end
end
