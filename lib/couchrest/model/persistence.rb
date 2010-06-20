module CouchRest
  module Model
    module Persistence
      extend ActiveSupport::Concern

      # Create the document. Validation is enabled by default and will return 
      # false if the document is not valid. If all goes well, the document will
      # be returned.
      def create(options = {})
        return false unless perform_validations(options)
        _run_create_callbacks do
          _run_save_callbacks do
            set_unique_id if new? && self.respond_to?(:set_unique_id)
            result = database.save_doc(self)
            (result["ok"] == true) ? self : false
          end
        end
      end
     
      # Creates the document in the db. Raises an exception
      # if the document is not created properly.
      def create!
        self.class.fail_validate!(self) unless self.create
      end
      
      # Trigger the callbacks (before, after, around)
      # only if the document isn't new
      def update(options = {})
        raise "Calling #{self.class.name}#update on document that has not been created!" if self.new?
        return false unless perform_validations(options)
        _run_update_callbacks do
          _run_save_callbacks do
            result = database.save_doc(self)
            result["ok"] == true
          end
        end
      end
      
      # Trigger the callbacks (before, after, around) and save the document
      def save(options = {})
        self.new? ? create(options) : update(options)
      end
      
      # Saves the document to the db using save. Raises an exception
      # if the document is not saved properly.
      def save!
        self.class.fail_validate!(self) unless self.save
        true
      end

      # Deletes the document from the database. Runs the :destroy callbacks.
      # Removes the <tt>_id</tt> and <tt>_rev</tt> fields, preparing the
      # document to be saved to a new <tt>_id</tt> if required.
      def destroy
        _run_destroy_callbacks do
          result = database.delete_doc(self)
          if result['ok']
            self.delete('_rev')
            self.delete('_id')
          end
          result['ok']
        end
      end

    protected

      def perform_validations(options = {})
        perform_validation = case options
        when Hash
          options[:validate] != false
        else
          options
        end
        perform_validation ? valid? : true
      end


      module ClassMethods

        # Creates a new instance, bypassing attribute protection
        #
        #
        # ==== Returns
        #  a document instance
        def create_from_database(doc = {})
          base = (doc['couchrest-type'].blank? || doc['couchrest-type'] == self.to_s) ? self : doc['couchrest-type'].constantize
          base.new(doc, :directly_set_attributes => true)      
        end

        # Defines an instance and save it directly to the database 
        # 
        # ==== Returns
        #  returns the reloaded document
        def create(attributes = {})
          instance = new(attributes)
          instance.create
          instance
        end
        
        # Defines an instance and save it directly to the database 
        # 
        # ==== Returns
        #  returns the reloaded document or raises an exception
        def create!(attributes = {})
          instance = new(attributes)
          instance.create!
          instance
        end

        # Name a method that will be called before the document is first saved,
        # which returns a string to be used for the document's <tt>_id</tt>.
        #
        # Because CouchDB enforces a constraint that each id must be unique,
        # this can be used to enforce eg: uniq usernames. Note that this id
        # must be globally unique across all document types which share a
        # database, so if you'd like to scope uniqueness to this class, you
        # should use the class name as part of the unique id.
        def unique_id method = nil, &block
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

        # Raise an error if validation failed.
        def fail_validate!(document)
          raise Errors::Validations.new(document)
        end
      end
      

    end
  end
end
