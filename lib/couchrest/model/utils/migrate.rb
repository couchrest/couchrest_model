module CouchRest
  module Model
    module Utils

      # Handle CouchDB Design Document migrations.
      #
      # Actual migrations are handled by the Design document, this serves as a utility
      # to find all the CouchRest Model submodels and perform the migration on them.
      #
      # Also contains some more advanced support for handling proxied models.
      #
      # Examples of usage:
      #
      #    # Ensure all models have been loaded (only Rails)
      #    CouchRest::Model::Utils::Migrate.load_all_models
      #
      #    # Migrate all regular models (not proxied)
      #    CouchRest::Model::Utils::Migrate.all_models
      #
      #    # Migrate all models and submodels of proxies
      #    CouchRest::Model::Utils::Migrate.all_models_and_proxies
      #
      # Typically however you'd want to run these methods from the rake tasks:
      #
      #    $ rake couchrest:migrate_with_proxies
      #
      # NOTE: This is an experimental feature that is not yet properly tested.
      #
      module Migrate
        extend self

        # Make an attempt at loading all the files in this Rails application's
        # models directory.
        def load_all_models
          # Make a reasonable effort to load all models
          return unless defined?(Rails)
          Dir[Rails.root + 'app/models/**/*.rb'].each do |path|
            require path
          end
        end

        # Go through each class that inherits from CouchRest::Model::Base and
        # attempt to migrate the design documents.
        def all_models
          callbacks = migrate_each_model(find_models)
          cleanup(callbacks)
        end

        def all_models_and_proxies
          callbacks = migrate_each_model(find_models)
          callbacks += migrate_each_proxying_model(find_proxying_models)
          cleanup(callbacks)
        end

        protected

        def find_models
          CouchRest::Model::Base.subclasses.reject{|m| m.proxy_owner_method.present?}
        end

        def find_proxying_models
          CouchRest::Model::Base.subclasses.reject{|m| m.proxy_database_method.blank?}
        end

        def migrate_each_model(models, db = nil)
          callbacks = [ ]
          models.each do |model|
            model.design_docs.each do |design|
              callbacks << migrate_design(model, design, db)
            end
          end
          callbacks
        end

        def migrate_each_proxying_model(models)
          callbacks = [ ]
          models.each do |model|
            submodels = model.proxied_model_names.map{|n| n.constantize}
            model.all.each do |base|
              puts "Finding proxied models for #{model}: \"#{base.send(model.proxy_database_method)}\""
              callbacks += migrate_each_model(submodels, base.proxy_database)
            end
          end
          callbacks
        end

        def migrate_design(model, design, db = nil)
          print "Migrating #{model.to_s}##{design.method_name}... "
          callback = design.migrate(db) do |result|
            puts "#{result.to_s.gsub(/_/, ' ')}"
          end
          # Return the callback hash if there is one
          callback ? {:design => design, :proc => callback, :db => db || model.database} : nil
        end

        def cleanup(methods)
          methods.compact.each do |cb|
            name = "/#{cb[:db].name}/#{cb[:design]['_id']}"
            puts "Activating new design: #{name}"
            cb[:proc].call
          end
        end
      end
    end
  end
end
