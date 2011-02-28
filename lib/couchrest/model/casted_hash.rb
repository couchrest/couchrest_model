#
# Wrapper around Hash so that the casted_by attribute is set.

module CouchRest::Model
  class CastedHash < Hash
    include CouchRest::Model::Dirty
    attr_accessor :casted_by

    def []= index, obj
      couchrest_parent_will_change! if obj != self[index]
      super(index, obj)
    end

    # needed for dirty
    def attributes
      self
    end

  end
end
