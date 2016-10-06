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
      #    $ rake couchrest:designs:migrate_with_proxies
      #
      # In production environments, you sometimes want to prepare large view
      # indexes that take a long term to generate before activating them. To
      # support this scenario we provide the `:activate` option:
      #
      #    # Prepare all models, but do not activate
      #    CouchRest::Model::Utils::Migrate.all_models(activate: false)
      #
      # Or from Rake:
      #
      #    $ rake couchrest:designs:prepare
      #
      # Once finished, just before uploading your code you can repeat without
      # the `activate` option so that the view indexes are ready for the new
      # designs.
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
        def all_models(opts = {})
          opts.reverse_merge!(activate: true, with_proxies: false)
          callbacks = migrate_each_model(find_models)
          callbacks += migrate_each_proxying_model(find_proxying_base_models) if opts[:with_proxies]
          activate_designs(callbacks) if opts[:activate]
        end

        def all_models_and_proxies(opts = {})
          opts[:with_proxies] = true
          all_models(opts)
        end

        protected

        def find_models
          CouchRest::Model::Base.subclasses.reject{|m| m.proxy_owner_method.present?}
        end

        def find_proxying_base_models
          CouchRest::Model::Base.subclasses.reject{|m| m.proxy_method_names.empty? || m.proxy_owner_method.present?}
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
            model_class = model.is_a?(CouchRest::Model::Proxyable::ModelProxy) ? model.model : model
            methods = model_class.proxy_method_names
            methods.each do |method|
              puts "Finding proxied models for #{model_class}##{method}"
              model.all.each do |obj|
                proxy = obj.send(method)
                callbacks += migrate_each_model([proxy.model], proxy.database)
                callbacks += migrate_each_proxying_model([proxy]) unless model_class.proxy_method_names.empty?
              end
            end
          end
          callbacks
        end

        def migrate_design(model, design, db = nil)
          print "Migrating #{model.to_s}##{design.method_name}"
          print " on #{db.name}" if db
          print "... "
          callback = design.migrate(db) do |result|
            puts "#{result.to_s.gsub(/_/, ' ')}"
          end
          # Return the callback hash if there is one
          callback ? {:design => design, :proc => callback, :db => db || model.database} : nil
        end

        def activate_designs(methods)
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
