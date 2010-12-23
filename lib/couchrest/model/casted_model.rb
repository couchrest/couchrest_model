module CouchRest::Model
  module CastedModel
   
    extend ActiveSupport::Concern

    included do
      include CouchRest::Model::Configuration
      include CouchRest::Model::Callbacks
      include CouchRest::Model::Properties
      include CouchRest::Model::PropertyProtection
      include CouchRest::Model::Associations
      include CouchRest::Model::Validations
      attr_accessor :casted_by
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

    def persisted?
      !new?
    end

    # The to_param method is needed for rails to generate resourceful routes.
    # In your controller, remember that it's actually the id of the document.
    def id
      return nil if base_doc.nil?
      base_doc.id
    end
    alias :to_key :id
    alias :to_param :id
    
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
