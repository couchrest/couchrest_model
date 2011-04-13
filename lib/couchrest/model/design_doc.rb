# encoding: utf-8
module CouchRest
  module Model
    module DesignDoc
      extend ActiveSupport::Concern
      
      module ClassMethods
        
        def design_doc
          @design_doc ||= ::CouchRest::Design.new(default_design_doc)
        end
    
        # Use when something has been changed, like a view, so that on the next request
        # the design docs will be updated (if changed!)
        def req_design_doc_refresh
          @design_doc_fresh = { }
        end
        
        def design_doc_id
          "_design/#{design_doc_slug}"
        end

        def design_doc_slug
          self.to_s
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

        # DEPRECATED
        # use stored_design_doc to retrieve the current design doc
        def all_design_doc_versions(db = database)
          db.documents :startkey => "_design/#{self.to_s}", 
            :endkey => "_design/#{self.to_s}-\u9999"
        end
       
        # Retreive the latest version of the design document directly
        # from the database.
        def stored_design_doc(db = database)
          db.get(design_doc_id) rescue nil
        end
        alias :model_design_doc :stored_design_doc

        def refresh_design_doc(db = database)
          raise "Database missing for design document refresh" if db.nil?
          unless design_doc_fresh(db)
            save_design_doc(db)
            design_doc_fresh(db, true)
          end
        end

        # Save the design doc onto a target database in a thread-safe way,
        # not modifying the model's design_doc
        #
        # See also save_design_doc! to always save the design doc even if there
        # are no changes.
        def save_design_doc(db = database, force = false)
          update_design_doc(Design.new(design_doc), db, force)
        end

        # Force the update of the model's design_doc even if it hasn't changed.
        def save_design_doc!(db = database)
          save_design_doc(db, true)
        end

        protected

        def design_doc_fresh(db, fresh = nil)
          @design_doc_fresh ||= {}
          if fresh.nil? 
            @design_doc_fresh[db.uri] || false
          else
            @design_doc_fresh[db.uri] = fresh
          end
        end

        # Writes out a design_doc to a given database, returning the
        # updated design doc
        def update_design_doc(design_doc, db, force = false)
          design_doc['couchrest-hash'] = design_doc.checksum
          saved = stored_design_doc(db)
          if saved
            if force || saved['couchrest-hash'] != design_doc['couchrest-hash']
              saved.merge!(design_doc)
              db.save_doc(saved)
            end
          else
            db.save_doc(design_doc)
          end
          design_doc
        end

        # Return true if the two views match
        def compare_views(orig, repl)
          return false if orig.nil? or repl.nil?
          (orig['map'].to_s.strip == repl['map'].to_s.strip) && (orig['reduce'].to_s.strip == repl['reduce'].to_s.strip)
        end

      end # module ClassMethods

    end
  end
end
