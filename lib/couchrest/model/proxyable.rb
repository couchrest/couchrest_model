module CouchRest
  module Model
    # :nodoc: Because I like inventing words
    module Proxyable
      extend ActiveSupport::Concern

      def proxy_database(assoc_name)
        raise StandardError, "Please set the #proxy_database_method" if self.class.proxy_database_method.nil?
        db_name = self.send(self.class.proxy_database_method)
        db_suffix = self.class.proxy_database_suffixes[assoc_name.to_sym]
        @_proxy_databases ||= {}
        @_proxy_databases[assoc_name.to_sym] ||= begin
          self.class.prepare_database([db_name, db_suffix].compact.reject(&:blank?).join(self.class.connection[:join]))
        end
      end

      module ClassMethods


        # Define a collection that will use the base model for the database connection
        # details.
        def proxy_for(assoc_name, options = {})
          db_method = (options[:database_method] || "proxy_database").to_sym
          db_suffix = options[:database_suffix] || (options[:use_suffix] ? assoc_name.to_s : nil)
          options[:class_name] ||= assoc_name.to_s.singularize.camelize
          proxy_method_names   << assoc_name.to_sym    unless proxy_method_names.include?(assoc_name.to_sym)
          proxied_model_names  << options[:class_name] unless proxied_model_names.include?(options[:class_name])
          proxy_database_suffixes[assoc_name.to_sym] = db_suffix
          db_method_call = "#{db_method}(:#{assoc_name.to_s})"
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{assoc_name}
              @#{assoc_name} ||= CouchRest::Model::Proxyable::ModelProxy.new(::#{options[:class_name]}, self, self.class.to_s.underscore, #{db_method_call})
            end
          EOS
        end

        # Tell this model which other model to use as a base for the database
        # connection to use.
        def proxied_by(model_name, options = {})
          raise "Model can only be proxied once or ##{model_name} already defined" if method_defined?(model_name) || !proxy_owner_method.nil?
          self.proxy_owner_method = model_name
          attr_accessor :model_proxy
          attr_accessor model_name
          overwrite_database_reader(model_name)
        end

        # Define an a class variable accessor ready to be inherited and unique
        # for each Class using the base.
        # Perhaps there is a shorter way of writing this.
        def proxy_owner_method=(name); @proxy_owner_method = name; end
        def proxy_owner_method; @proxy_owner_method; end

        # Define the name of a method to call to determine the name of
        # the database to use as a proxy.
        def proxy_database_method(name = nil)
          @proxy_database_method = name if name
          @proxy_database_method
        end

        def proxy_method_names
          @proxy_method_names ||= []
        end

        def proxied_model_names
          @proxied_model_names ||= []
        end

        def proxy_database_suffixes
          @proxy_database_suffixes ||= {}
        end

        private

        # Ensure that no attempt is made to autoload a database connection
        # by overwriting it to provide a basic accessor.
        def overwrite_database_reader(model_name)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def self.database
              raise StandardError, "#{self.to_s} database must be accessed via '#{model_name}' proxy"
            end
          EOS
        end

      end

      class ModelProxy

        attr_reader :model, :owner, :owner_name, :database

        def initialize(model, owner, owner_name, database)
          @model      = model
          @owner      = owner
          @owner_name = owner_name
          @database   = database

          create_view_methods
        end

        # Base
        def new(attrs = {}, options = {}, &block)
          proxy_block_update(:new, attrs, options, &block)
        end

        def build_from_database(attrs = {}, options = {}, &block)
          proxy_block_update(:build_from_database, attrs, options, &block)
        end

        # From DocumentQueries (The old fashioned way)

        def count(opts = {})
          all(opts).count
        end

        def first(opts = {})
          all(opts).first
        end

        def last(opts = {})
          all(opts).last
        end

        def get(id)
          get!(id)
        rescue CouchRest::Model::DocumentNotFound
          nil
        end
        alias :find :get

        def get!(id)
          proxy_update(@model.fetch_and_build_from_database(id, @database))
        end
        alias :find! :get!

        protected

        def create_view_methods
          model.design_docs.each do |doc|
            doc.view_names.each do |name|
              class_eval <<-EOS, __FILE__, __LINE__ + 1
                def #{name}(opts = {})
                  model.#{name}({:proxy => self}.merge(opts))
                end
                def find_#{name}(*key)
                  #{name}.key(*key).first()
                end
                def find_#{name}!(*key)
                  find_#{name}(*key) || raise(CouchRest::Model::DocumentNotFound)
                end
              EOS
            end
          end
        end

        # Update the document's proxy details, specifically, the fields that
        # link back to the original document.
        def proxy_update(doc)
          if doc && doc.is_a?(model)
            doc.database = @database
            doc.model_proxy = self
            doc.send("#{owner_name}=", owner)
          end
          doc
        end

        def proxy_update_all(docs)
          docs.each do |doc|
            proxy_update(doc)
          end
        end

        def proxy_block_update(method, *args, &block)
          model.send(method, *args) do |doc|
            proxy_update(doc)
            yield doc if block_given?
          end
        end

        private

        def method_missing(m, *args, &block)
          model.respond_to?(m) ? model.send(m, self, *args, &block) : super
        end
        
      end
    end
  end
end
