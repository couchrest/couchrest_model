module CouchRest
  module Model
    module Persistence
      extend ActiveSupport::Concern

      # Create the document. Validation is enabled by default and will return
      # false if the document is not valid. If all goes well, the document will
      # be returned.
      def create(options = {})
        return false unless perform_validations(options)
        run_callbacks :create do
          run_callbacks :save do
            set_unique_id if new? && respond_to?(:set_unique_id)
            result = database.save_doc(self)
            ret = (result["ok"] == true) ? self : false
            clear_changes_information if ret
            ret
          end
        end
      end

      # Creates the document in the db. Raises an exception
      # if the document is not created properly.
      def create!(options = {})
        self.class.fail_validate!(self) unless self.create(options)
      end

      # Trigger the callbacks (before, after, around)
      # only if the document isn't new
      def update(options = {})
        raise "Cannot save a destroyed document!" if destroyed?
        raise "Calling #{self.class.name}#update on document that has not been created!" if new?
        return false unless perform_validations(options)
        return true unless changed?
        run_callbacks :update do
          run_callbacks :save do
            result = database.save_doc(self)
            ret = result["ok"] == true
            clear_changes_information if ret
            ret
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
      def destroy
        run_callbacks :destroy do
          result = database.delete_doc(self)
          if result['ok']
            @_destroyed = true
            self.freeze
          end
          result['ok']
        end
      end

      def destroyed?
        !!@_destroyed
      end

      def persisted?
        !new? && !destroyed?
      end

      # Update the document's attributes and save. For example:
      #
      #   doc.update_attributes :name => "Fred"
      # Is the equivilent of doing the following:
      #
      #   doc.attributes = { :name => "Fred" }
      #   doc.save
      #
      def update_attributes(hash)
        write_attributes(hash)
        save
      end

      # Reloads the attributes of this object from the database.
      # It doesn't override custom instance variables.
      #
      # Returns self.
      def reload
        write_attributes_for_initialization(
          database.get!(id), :write_all_attributes => true
        )
        self
      rescue CouchRest::NotFound
        raise CouchRest::Model::DocumentNotFound
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

        # Creates a new instance, bypassing attribute protection and
        # uses the type field to determine which model to use to instanatiate
        # the new object.
        #
        # ==== Returns
        #  a document instance
        #
        def build_from_database(doc = {}, options = {}, &block)
          src = doc[model_type_key]
          base = (src.blank? || src == model_type_value) ? self : src.constantize
          base.new(doc, options.merge(:write_all_attributes => true), &block)
        end

        # Defines an instance and save it directly to the database
        #
        # ==== Returns
        #  returns the reloaded document
        def create(attributes = {}, &block)
          instance = new(attributes, &block)
          instance.create
          instance
        end

        # Defines an instance and save it directly to the database
        #
        # ==== Returns
        #  returns the reloaded document or raises an exception
        def create!(attributes = {}, &block)
          instance = new(attributes, &block)
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
        def unique_id(method = nil, &block)
          return if method.nil? && !block
          define_method :set_unique_id do
            uniqid = method.nil? ? block.call(self) : send(method)
            raise ArgumentError, "unique_id cannot be nil nor empty" if uniqid.blank?
            self['_id'] ||= uniqid
          end
        end

        # The value to use for this model's model_type_key.
        # By default, this shouls always be the string representation of the class,
        # but if you need anything special, overwrite this method.
        def model_type_value
          to_s
        end

        # Raise an error if validation failed.
        def fail_validate!(document)
          raise Errors::Validations.new(document)
        end
      end


    end
  end
end
