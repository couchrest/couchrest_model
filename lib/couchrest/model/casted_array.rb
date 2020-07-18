#
# Wrapper around Array so that the casted_by attribute is set in all
# elements of the array.
#

module CouchRest::Model
  class CastedArray < Array
    include CouchRest::Model::Configuration
    include CouchRest::Model::CastedBy
    include CouchRest::Model::Dirty

    def initialize(array, property, parent = nil)
      self.casted_by_property = property
      self.casted_by = parent unless parent.nil?
      super(array)
    end

    # Adding new entries

    def << obj
      super(instantiate_and_cast(obj))
    end

    def push(obj)
      super(instantiate_and_cast(obj))
    end

    def unshift(obj)
      super(instantiate_and_cast(obj))
    end

    def []=(index, obj)
      super(index, instantiate_and_cast(obj))
    end

    def insert(index, *args)
      values = args.map{|obj| instantiate_and_cast(obj)}
      super(index, *values)
    end

    def build(*args)
      obj = casted_by_property.build(*args)
      self.push(obj)
      obj
    end

    def as_couch_json
      map{ |v| (v.respond_to?(:as_couch_json) ? v.as_couch_json : v)}
    end

    # Overwrite the standard dirty tracking clearing.
    # We don't have any properties, but we do need to check
    # entries in our array.
    def clear_changes_information
      if use_dirty?
        each do |val|
          if val.respond_to?(:clear_changes_information)
            val.clear_changes_information
          end
        end
        @original_change_data = current_change_data
      else
        @original_change_data = nil
      end
    end

    protected

    def instantiate_and_cast(obj)
      property = casted_by_property
      if casted_by && property && obj.class != property.type
        property.cast_value(casted_by, obj)
      else
        obj.casted_by = casted_by if obj.respond_to?(:casted_by)
        obj.casted_by_property = casted_by_property if obj.respond_to?(:casted_by_property)
        obj
      end
    end
  end
end
