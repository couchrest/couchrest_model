module CouchRest
  module CastedModel
    
    def self.included(base)
      base.send(:include, ::CouchRest::Mixins::AttributeProtection)
      base.send(:include, ::CouchRest::Mixins::Attributes)
      base.send(:include, ::CouchRest::Mixins::Callbacks)
      base.send(:include, ::CouchRest::Mixins::Properties)
      base.send(:include, ::CouchRest::Mixins::Associations)
      base.send(:attr_accessor, :casted_by)
    end
    
    def initialize(keys = {})
      raise StandardError unless self.is_a? Hash
      prepare_all_attributes(keys)
      super()
    end
    
    def []= key, value
      super(key.to_s, value)
    end
    
    def [] key
      super(key.to_s)
    end
    
    # Gets a reference to the top level extended
    # document that a model is saved inside of
    def base_doc
      return nil unless @casted_by
      @casted_by.base_doc
    end
    
    # False if the casted model has already
    # been saved in the containing document
    def new?
      @casted_by.nil? ? true : @casted_by.new?
    end
    alias :new_record? :new?
    
    # Sets the attributes from a hash
    def update_attributes_without_saving(hash)
      hash.each do |k, v|
        raise NoMethodError, "#{k}= method not available, use property :#{k}" unless self.respond_to?("#{k}=")
      end      
      hash.each do |k, v|
        self.send("#{k}=",v)
      end
    end
    alias :attributes= :update_attributes_without_saving
    
  end
end
