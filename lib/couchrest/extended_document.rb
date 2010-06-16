
require File.join(File.dirname(__FILE__), "property")
require File.join(File.dirname(__FILE__), "validation")
require File.join(File.dirname(__FILE__), 'mixins')

module CouchRest
  
  # Same as CouchRest::Document but with properties and validations
  class ExtendedDocument < Document

    VERSION = "1.0.0.beta5"

    include CouchRest::Mixins::Callbacks
    include CouchRest::Mixins::DocumentQueries    
    include CouchRest::Mixins::Views
    include CouchRest::Mixins::DesignDoc
    include CouchRest::Mixins::ExtendedAttachments
    include CouchRest::Mixins::ClassProxy
    include CouchRest::Mixins::Collection
    include CouchRest::Mixins::AttributeProtection
    include CouchRest::Mixins::Attributes

    # Including validation here does not work due to the way inheritance is handled.
    #include CouchRest::Validation

    def self.subclasses
      @subclasses ||= []
    end
    
    def self.inherited(subklass)
      super
      subklass.send(:include, CouchRest::Mixins::Properties)
      subklass.class_eval <<-EOS, __FILE__, __LINE__ + 1
        def self.inherited(subklass)
          super
          subklass.properties = self.properties.dup
        end
      EOS
      subclasses << subklass
    end
    
    # Accessors
    attr_accessor :casted_by
    
    # Callbacks
    define_callbacks :create, "result == :halt"
    define_callbacks :save, "result == :halt"
    define_callbacks :update, "result == :halt"
    define_callbacks :destroy, "result == :halt"

    # Creates a new instance, bypassing attribute protection
    #
    #
    # ==== Returns
    #  a document instance
    def self.create_from_database(doc = {})
      base = (doc['couchrest-type'].blank? || doc['couchrest-type'] == self.to_s) ? self : doc['couchrest-type'].constantize
      base.new(doc, :directly_set_attributes => true)      
    end
    

    # Instantiate a new ExtendedDocument by preparing all properties
    # using the provided document hash.
    #
    # Options supported:
    # 
    # * :directly_set_attributes: true when data comes directly from database
    #
    def initialize(doc = {}, options = {})
      prepare_all_attributes(doc, options) # defined in CouchRest::Mixins::Attributes
      super(doc)
      unless self['_id'] && self['_rev']
        self['couchrest-type'] = self.class.to_s
      end
      after_initialize if respond_to?(:after_initialize)
    end
    
    # Defines an instance and save it directly to the database 
    # 
    # ==== Returns
    #  returns the reloaded document
    def self.create(options)
      instance = new(options)
      instance.create
      instance
    end
    
    # Defines an instance and save it directly to the database 
    # 
    # ==== Returns
    #  returns the reloaded document or raises an exception
    def self.create!(options)
      instance = new(options)
      instance.create!
      instance
    end
    
    # Automatically set <tt>updated_at</tt> and <tt>created_at</tt> fields
    # on the document whenever saving occurs. CouchRest uses a pretty
    # decent time format by default. See Time#to_json
    def self.timestamps!
      class_eval <<-EOS, __FILE__, __LINE__
        property(:updated_at, Time, :read_only => true, :protected => true, :auto_validation => false)
        property(:created_at, Time, :read_only => true, :protected => true, :auto_validation => false)
        
        set_callback :save, :before do |object|
          write_attribute('updated_at', Time.now)
          write_attribute('created_at', Time.now) if object.new?
        end
      EOS
    end
    
    # Name a method that will be called before the document is first saved,
    # which returns a string to be used for the document's <tt>_id</tt>.
    # Because CouchDB enforces a constraint that each id must be unique,
    # this can be used to enforce eg: uniq usernames. Note that this id
    # must be globally unique across all document types which share a
    # database, so if you'd like to scope uniqueness to this class, you
    # should use the class name as part of the unique id.
    def self.unique_id method = nil, &block
      if method
        define_method :set_unique_id do
          self['_id'] ||= self.send(method)
        end
      elsif block
        define_method :set_unique_id do
          uniqid = block.call(self)
          raise ArgumentError, "unique_id block must not return nil" if uniqid.nil?
          self['_id'] ||= uniqid
        end
      end
    end
    
    # Temp solution to make the view_by methods available
    def self.method_missing(m, *args, &block)
      if has_view?(m)
        query = args.shift || {}
        return view(m, query, *args, &block)
      elsif m.to_s =~ /^find_(by_.+)/
        view_name = $1
        if has_view?(view_name)
          query = {:key => args.first, :limit => 1}
          return view(view_name, query).first
        end
      end
      super
    end
    
    ### instance methods
    
    # Gets a reference to the actual document in the DB
    # Calls up to the next document if there is one,
    # Otherwise we're at the top and we return self
    def base_doc
      return self if base_doc?
      @casted_by.base_doc
    end
    
    # Checks if we're the top document
    def base_doc?
      !@casted_by
    end
    
    # for compatibility with old-school frameworks
    alias :new_record? :new?
    alias :new_document? :new?
    
    # Trigger the callbacks (before, after, around)
    # and create the document
    # It's important to have a create callback since you can't check if a document
    # was new after you saved it
    #
    # When creating a document, both the create and the save callbacks will be triggered.
    def create(bulk = false)
      caught = catch(:halt)  do
        _run_create_callbacks do
            _run_save_callbacks do
              create_without_callbacks(bulk)
          end
        end
      end
    end
    
    # unlike save, create returns the newly created document
    def create_without_callbacks(bulk =false)
      raise ArgumentError, "a document requires a database to be created to (The document or the #{self.class} default database were not set)" unless database
      set_unique_id if new? && self.respond_to?(:set_unique_id)
      result = database.save_doc(self, bulk)
      (result["ok"] == true) ? self : false
    end
    
    # Creates the document in the db. Raises an exception
    # if the document is not created properly.
    def create!
      raise "#{self.inspect} failed to save" unless self.create
    end
    
    # Trigger the callbacks (before, after, around)
    # only if the document isn't new
    def update(bulk = false)
      caught = catch(:halt)  do
        if self.new?
          save(bulk)
        else
          _run_update_callbacks do
            _run_save_callbacks do
              save_without_callbacks(bulk)
            end
          end
        end
      end
    end
    
    # Trigger the callbacks (before, after, around)
    # and save the document
    def save(bulk = false)
      caught = catch(:halt)  do
        if self.new?
          _run_save_callbacks do
            save_without_callbacks(bulk)
          end
        else
          update(bulk)
        end
      end
    end
    
    # Overridden to set the unique ID.
    # Returns a boolean value
    def save_without_callbacks(bulk = false)
      raise ArgumentError, "a document requires a database to be saved to (The document or the #{self.class} default database were not set)" unless database
      set_unique_id if new? && self.respond_to?(:set_unique_id)
      result = database.save_doc(self, bulk)
      result["ok"] == true
    end
    
    # Saves the document to the db using save. Raises an exception
    # if the document is not saved properly.
    def save!
      raise "#{self.inspect} failed to save" unless self.save
      true
    end

    # Deletes the document from the database. Runs the :destroy callbacks.
    # Removes the <tt>_id</tt> and <tt>_rev</tt> fields, preparing the
    # document to be saved to a new <tt>_id</tt>.
    def destroy(bulk=false)
      caught = catch(:halt)  do
        _run_destroy_callbacks do
          result = database.delete_doc(self, bulk)
          if result['ok']
            self.delete('_rev')
            self.delete('_id')
          end
          result['ok']
        end
      end
    end
  
  end
end
