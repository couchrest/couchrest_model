
module CouchRest
  module Model
    module Designs

      class Design < ::CouchRest::Design

        # The model Class that this design belongs to
        attr_accessor :model

        # Can this design save itself to the database?
        # If false, the design will be loaded automatically before a view is executed.
        attr_accessor :auto_update


        # Instantiate a new design document for this model
        def initialize(model, prefix = nil)
          self.model  = model
          suffix = prefix ? "_#{prefix}" : ''
          self["_id"] = "_design/#{model.to_s}#{suffix}"
          apply_defaults
        end

        # Create a new view object.
        # This overrides the normal CouchRest Design view method
        def view(name, opts = {})
          CouchRest::Model::Designs::View.new(self, model, opts, name)
        end

        def sync(db = nil)
          if auto_update
            db ||= database

            # do we need to continue?
            return self if cache_checksum(db) == checksum

            # Load up the last copy. We never overwrite the remote copy
            # as it may contain views that are not used or known about by
            # our model.
            doc = load_from_database(db)

            if !doc || doc['couchrest-hash'] != checksum
              # We need to save something
              if doc
                # Different! Update.
                doc.merge!(to_hash)
              else
                # No previous doc, use our version.
                doc = self
              end
              db.save_doc(doc)
            end

            set_cache_checksum(db, checksum)
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

        # Helper method to provide a list of all the views
        def view_names
          self['views'].keys
        end

        protected

        def load_from_database(db = database)
          db.get(self['_id'])
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

      end
    end
  end
end


