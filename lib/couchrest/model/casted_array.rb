#
# Wrapper around Array so that the casted_by attribute is set in all
# elements of the array.
#

module CouchRest::Model
  class CastedArray < Array
    include CouchRest::Model::Dirty
    attr_accessor :casted_by
    attr_accessor :property

    def initialize(array, property)
      self.property = property
      super(array)
    end
    
    def << obj
      couchrest_parent_will_change!
      super(instantiate_and_cast(obj))
    end
    
    def push(obj)
      couchrest_parent_will_change!
      super(instantiate_and_cast(obj))
    end

    def pop
      couchrest_parent_will_change!
      super
    end

    def shift
      couchrest_parent_will_change!
      super
    end

    def unshift(obj)
      couchrest_parent_will_change!
      super(obj)
    end
    
    def []= index, obj
      value = instantiate_and_cast(obj)
      couchrest_parent_will_change! if value != self[index]
      super(index, value)
    end

    protected

    def instantiate_and_cast(obj)
      if self.casted_by && self.property && obj.class != self.property.type_class
        self.property.cast_value(self.casted_by, obj)
      else
        obj.casted_by = self.casted_by if obj.respond_to?(:casted_by)
        obj
      end
    end
  end
end
