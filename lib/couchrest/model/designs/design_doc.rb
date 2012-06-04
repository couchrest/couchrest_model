
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
        def view(opts = {}, name = nil)
          CouchRest::Model::Designs::View.new(self, model, opts, name)
        end

        def sync(db = nil)
          if auto_update
            db ||= model.database

            # do we need to continue?
            return self if cache_checksum(db) == checksum

            # Load up the last copy. We never overwrite the remote copy
            # as it may contain views that are not used or known about by
            # our model.
            doc = load_from_database(database)
            if doc
              return self if doc['couchrest-hash'] == checksum
              # Different! Update.
              doc.merge!(to_hash)
            else
              # No previous doc, use our version.
              doc = self
            end
            db.save_doc(doc)

            set_cache_checksum(db, checksum)
            self
          end
        end

        def checksum
          self['couchrest-hash'] || checksum!
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

        # Override the default #uri method for one that accepts
        # the current database.
        # This is used by the caching code.
        def uri(db)
          "#{db.root}/#{self['_id']}"
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


