module CouchRest
  module Model

    # Handle CouchDB migrations.
    #
    # Actual migrations are handled by the Design document, this serves as a utility
    # to find all the CouchRest Model submodels and perform the migration on them.
    #
    # Also contains some more advanced support for handling proxied models.
    #
    # Examples of usage:
    #
    #    # Ensure all models have been loaded (only Rails)
    #    CouchRest::Model::Migrate.load_all_models
    #
    #    # Migrate all regular models (not proxied)
    #    CouchRest::Model::Migrate.all_models
    #
    #    # Migrate all models and submodels of proxies
    #    CouchRest::Model::Migrate.all_models_and_proxies
    #
    class Migrate

      def self.all_models
        callbacks = migrate_each_model(find_models)
        cleanup(callbacks)
      end

      def self.all_models_and_proxies
        callbacks = migrate_each_model(find_models)
        callbacks += migrate_each_proxying_model(find_proxying_models)
        cleanup(callbacks)
      end

      def self.load_all_models
        # Make a reasonable effort to load all models
        return unless defined?(Rails)
        Dir[Rails.root + 'app/models/**/*.rb'].each do |path|
          require path
        end
      end

      def self.find_models
        CouchRest::Model::Base.subclasses.reject{|m| m.proxy_owner_method.present?}
      end

      def self.find_proxying_models
        CouchRest::Model::Base.subclasses.reject{|m| m.proxy_database_method.blank?}
      end

      def self.migrate_each_model(models, db = nil)
        callbacks = [ ]
        models.each do |model|
          model.design_docs.each do |design|
            callbacks << migrate_design(model, design, db = nil)
          end
        end
        callbacks
      end

      def self.migrate_each_proxying_model(models)
        callbacks = [ ]
        models.each do |model|
          submodels = model.proxied_model_names.map{|n| n.constantize}
          model.all.each do |base|
            puts "Migrating proxied models for #{model}:\"#{base.send(model.proxy_database_method)}\""
            callbacks += migrate_each_model(submodels, base.proxy_database)
          end
        end
        callbacks
      end

      def self.migrate_design(model, design, db = nil)
        print "Migrating #{model.to_s}##{design.method_name}... "
        callback = design.migrate(db) do |result|
          puts "#{result.to_s.gsub(/_/, ' ')}"
        end
        # Return the callback hash if there is one
        callback ? {:design => design, :proc => callback, :db => db || model.database} : nil
      end

      def self.cleanup(methods)
        callbacks.compact.each do |cb|
          name = "/#{cb[:db].name}/#{db[:design]['_id']}"
          puts "Activating new design: #{name}"
          cb[:proc].call
        end
      end

    end
  end
end
