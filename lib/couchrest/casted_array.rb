#
# Wrapper around Array so that the casted_by attribute is set in all
# elements of the array.
#

module CouchRest
  class CastedArray < Array
    attr_accessor :casted_by
    attr_accessor :property

    def initialize(array, property)
      self.property = property
      super(array)
    end
    
    def << obj
      super(instantiate_and_cast(obj))
    end
    
    def push(obj)
      super(instantiate_and_cast(obj))
    end
    
    def []= index, obj
      super(index, instantiate_and_cast(obj))
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
