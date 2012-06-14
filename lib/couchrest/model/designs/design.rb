
module CouchRest
  module Model
    module Designs

      class Design < ::CouchRest::Design

        # The model Class that this design belongs to and method name
        attr_accessor :model, :method_name

        # Can this design save itself to the database?
        # If false, the design will be loaded automatically before a view is executed.
        attr_accessor :auto_update


        # Instantiate a new design document for this model
        def initialize(model, prefix = nil)
          self.model       = model
          self.method_name = self.class.method_name(prefix)
          suffix = prefix ? "_#{prefix}" : ''
          self["_id"] = "_design/#{model.to_s}#{suffix}"
          apply_defaults
        end

        def sync(db = nil)
          if auto_update
            db ||= database
            if cache_checksum(db) != checksum
              sync!(db)
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

        # Migrate the design document preventing downtime on a production
        # system. Typically this will be used when auto updates are disabled.
        #
        # Steps taken are:
        #
        #  1. Compare the checksum with the current version
        #  2. If different, create a new design doc with timestamp
        #  3. Wait until the view returns a result
        #  4. Copy over the original design doc
        #
        # If a block is provided, it will be called with the result of the migration:
        #
        #  * :no_change - Nothing performed as there are no changes.
        #  * :created   - Add a new design doc as non existed
        #  * :migrated  - Migrated the existing design doc.
        #
        # This can be used for progressivly printing the results of the migration.
        #
        # After completion, either a "cleanup" Proc object will be provided to finalize
        # the process and copy the document into place, or simply nil if no cleanup is
        # required. For example:
        #
        #     print "Synchronising Cat model designs: "
        #     callback = Cat.design_doc.migrate do |res|
        #       puts res.to_s
        #     end
        #     if callback
        #       puts "Cleaning up."
        #       callback.call
        #     end
        #
        def migrate(db = nil, &block)
          db    ||= database
          doc     = load_from_database(db)
          cleanup = nil
          id      = self['_id']

          if !doc
            # no need to migrate, just save it
            new_doc = to_hash.dup
            db.save_doc(new_doc)

            result = :created
          elsif doc['couchrest-hash'] != checksum
            id += "_migration"

            # Delete current migration if there is one
            old_migration = load_from_database(db, id)
            db.delete_doc(old_migration) if old_migration

            # Save new design doc
            new_doc = doc.merge(to_hash)
            new_doc['_id'] = id
            new_doc.delete('_rev')
            db.save_doc(new_doc)

            # Proc definition to copy the migration doc over the original
            cleanup = Proc.new do
              db.copy_doc(new_doc, doc)
              db.delete_doc(new_doc)
              self
            end

            result = :migrated
          else
            # Already up to date
            result = :no_change
          end

          if new_doc && !new_doc['views'].empty?
            # Create a view query and send
            name = new_doc['views'].keys.first
            view = new_doc['views'][name]
            params = {:limit => 1}
            params[:reduce] = false if view['reduce']
            db.view("#{id}/_view/#{name}", params) do |res|
              # Block to use streamer!
            end
          end

          # Provide the result in block
          yield result if block_given?

          cleanup
        end

        # Perform a single migration and inmediatly request a cleanup operation:
        #
        #     print "Synchronising Cat model designs: "
        #     Cat.design_doc.migrate! do |res|
        #       puts res.to_s
        #     end
        #
        def migrate!(db = nil, &block)
          callback = migrate(db, &block)
          if callback.is_a?(Proc)
            callback.call
          else
            callback
          end
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
          View.define_and_create(self, name, opts)
        end

        ######## FILTER HANDLING ########

        def create_filter(name, function)
          filters = (self['filters'] ||= {})
          filters[name.to_s] = function
        end

        protected

        def load_from_database(db = database, id = nil)
          id ||= self['_id']
          db.get(id)
        rescue RestClient::ResourceNotFound
          nil
        end

        # Calculate and update the checksum of the Design document.
        # Used for ensuring the latest version has been sent to the database.
        #
        # This will generate an flatterned, ordered array of all the elements of the
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
          result = nil
          flatten =
            lambda {|r|
              (recurse = lambda {|v|
                if v.is_a?(Hash) || v.is_a?(CouchRest::Document)
                  v.to_a.map{|v| recurse.call(v)}.flatten
                elsif v.is_a?(Array)
                  v.flatten.map{|v| recurse.call(v)}
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
end


