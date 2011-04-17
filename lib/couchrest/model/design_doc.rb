# encoding: utf-8
module CouchRest
  module Model
    module DesignDoc
      extend ActiveSupport::Concern

      module ClassMethods

        def design_doc
          @design_doc ||= ::CouchRest::Design.new(default_design_doc)
        end

        def design_doc_id
          "_design/#{design_doc_slug}"
        end

        def design_doc_slug
          self.to_s
        end

        def design_doc_full_url(db = database)
          "#{db.uri}/#{design_doc_id}"
        end

        # Retreive the latest version of the design document directly
        # from the database. This is never cached and will return nil if
        # the design is not present.
        #
        # Use this method if you'd like to compare revisions [_rev] which
        # is not stored in the normal design doc.
        def stored_design_doc(db = database)
          db.get(design_doc_id)
        rescue RestClient::ResourceNotFound
          nil
        end

        # Save the design doc onto a target database in a thread-safe way,
        # not modifying the model's design_doc
        #
        # See also save_design_doc! to always save the design doc even if there
        # are no changes.
        def save_design_doc(db = database, force = false)
          update_design_doc(db, force)
        end

        # Force the update of the model's design_doc even if it hasn't changed.
        def save_design_doc!(db = database)
          save_design_doc(db, true)
        end

        private

        def design_doc_cache
          Thread.current[:couchrest_design_cache] ||= {}
        end
        def design_doc_cache_checksum(db)
          design_doc_cache[design_doc_full_url(db)]
        end
        def set_design_doc_cache_checksum(db, checksum)
          design_doc_cache[design_doc_full_url(db)] = checksum
        end

        # Writes out a design_doc to a given database if forced
        # or the stored checksum is not the same as the current
        # generated checksum.
        #
        # Returns the original design_doc provided, but does 
        # not update it with the revision.
        def update_design_doc(db, force = false)
          return design_doc unless force || auto_update_design_doc

          # Grab the design doc's checksum
          checksum = design_doc.checksum!

          # If auto updates enabled, check checksum cache
          return design_doc if auto_update_design_doc && design_doc_cache_checksum(db) == checksum

          # Load up the stored doc (if present), update, and save
          saved = stored_design_doc(db)
          if saved
            if force || saved['couchrest-hash'] != checksum
              saved.merge!(design_doc)
              db.save_doc(saved)
            end
          else
            db.save_doc(design_doc)
            design_doc.delete('_rev') # Prevent conflicts, never store rev as DB specific
          end

          # Ensure checksum cached for next attempt if using auto updates
          set_design_doc_cache_checksum(db, checksum) if auto_update_design_doc
          design_doc
        end

        def default_design_doc
          {
            "_id" => design_doc_id,
            "language" => "javascript",
            "views" => {
              'all' => {
                'map' => "function(doc) {
                  if (doc['#{self.model_type_key}'] == '#{self.to_s}') {
                    emit(doc['_id'],1);
                  }
                }"
              }
            }
          }
        end



      end # module ClassMethods

    end
  end
end
