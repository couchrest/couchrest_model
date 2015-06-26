module CouchRest
  module Model
    module Designs

      # Design Document Migrations Support
      #
      # A series of methods used inside design documents in order to perform migrations.
      #
      module Migrations

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

          wait_for_view_update_completion(db, new_doc)

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

        private

        def wait_for_view_update_completion(db, attrs)
          if attrs && !attrs['views'].empty?
            # Prepare a design doc we can use
            doc = CouchRest::Design.new(attrs)
            doc.database = db

            # Request view, to trigger a *background* view update
            doc.view(doc['views'].keys.first, :limit => 1, :stale => "ok")

            # Poll the view update process
            while true
              info = doc.info
              if !info || !info['view_index']
                raise "Migration error, unable to load design doc info: #{db.root}/#{doc.id}"
              end
              break if !info['view_index']['updater_running']
              sleep 1
            end
          end
        end


      end

    end
  end
end
