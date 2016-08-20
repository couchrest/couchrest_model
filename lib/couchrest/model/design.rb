
module CouchRest
  module Model

    class Design < ::CouchRest::Design
      include ::CouchRest::Model::Designs::Migrations

      # The model Class that this design belongs to and method name
      attr_accessor :model, :method_name

      # Can this design save itself to the database?
      # If false, the design will be loaded automatically before a view is executed.
      attr_accessor :auto_update


      # Instantiate a new design document for this model
      def initialize(model, prefix = nil)
        self.model       = model
        self.method_name = self.class.method_name(prefix)
        @lock            = Mutex.new
        suffix = prefix ? "_#{prefix}" : ''
        self["_id"] = "_design/#{model.to_s}#{suffix}"
        apply_defaults
      end

      def sync(db = nil)
        if auto_update
          db ||= database
          if cache_checksum(db) != checksum
            # Only allow one thread to update the design document at a time
            @lock.synchronize { sync!(db) }
            set_cache_checksum(db, checksum)
          end
        end
        self
      end

      def sync!(db = nil)
        db ||= database

        # Load up the last copy. We never blindly overwrite the remote copy
        # as it may contain views that are not used or known about by
        # our model.

        doc = load_from_database(db)

        if !doc || doc['couchrest-hash'] != checksum
          # We need to save something
          if doc
            # Different! Update.
            doc.merge!(to_hash)
          else
            # No previous doc, use a *copy* of our version.
            # Using a copy prevents reverse updates.
            doc = to_hash.dup
          end
          db.save_doc(doc)
        end

        self
      end

      def checksum
        sum = self['couchrest-hash']
        if sum && (@_original_hash == to_hash)
          sum
        else
          checksum!
        end
      end

      def database
        model.database
      end

      # Override the default #uri method for one that accepts
      # the current database.
      # This is used by the caching code.
      def uri(db = database)
        "#{db.root}/#{self['_id']}"
      end


      ######## VIEW HANDLING ########

      # Create a new view object.
      # This overrides the normal CouchRest Design view method
      def view(name, opts = {})
        CouchRest::Model::Designs::View.new(self, model, opts, name)
      end

      # Helper method to provide a list of all the views
      def view_names
        self['views'].keys
      end

      def has_view?(name)
        view_names.include?(name.to_s)
      end

      # Add the specified view to the design doc the definition was made in
      # and create quick access methods in the model.
      def create_view(name, opts = {})
        Designs::View.define_and_create(self, name, opts)
      end

      ######## FILTER HANDLING ########

      def create_filter(name, function)
        filters = (self['filters'] ||= {})
        filters[name.to_s] = function
      end

      ######## VIEW LIBS #########

      def create_view_lib(name, function)
        filters = (self['views']['lib'] ||= {})
        filters[name.to_s] = function
      end

      protected

      def load_from_database(db = database, id = nil)
        id ||= self['_id']
        db.get(id)
      end

      # Calculate and update the checksum of the Design document.
      # Used for ensuring the latest version has been sent to the database.
      #
      # This will generate a flatterned, ordered array of all the elements of the
      # design document, convert to string then generate an MD5 Hash. This should
      # result in a consisitent Hash accross all platforms.
      #
      def checksum!
        # Get a deep copy of hash to compare with
        @_original_hash = Marshal.load(Marshal.dump(to_hash))
        # create a copy of basic elements
        base = self.dup
        base.delete('_id')
        base.delete('_rev')
        base.delete('couchrest-hash')
        flatten =
          lambda {|r|
            (recurse = lambda {|v|
              if v.is_a?(Hash) || v.is_a?(CouchRest::Document)
                v.to_a.map{|p| recurse.call(p)}.flatten
              elsif v.is_a?(Array)
                v.flatten.map{|p| recurse.call(p)}
              else
                v.to_s
              end
            }).call(r)
          }
        self['couchrest-hash'] = Digest::MD5.hexdigest(flatten.call(base).sort.join(''))
      end

      def cache
        Thread.current[:couchrest_design_cache] ||= {}
      end
      def cache_checksum(db)
        cache[uri(db)]
      end
      def set_cache_checksum(db, checksum)
        cache[uri(db)] = checksum
      end

      def apply_defaults
        merge!(
          "language" => "javascript",
          "views"    => { }
        )
      end


      class << self

        def method_name(prefix = nil)
          (prefix ? "#{prefix}_" : '') + 'design_doc'
        end

      end

    end
  end
end
