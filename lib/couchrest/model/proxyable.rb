module CouchRest
  module Model
    # :nodoc: Because I like inventing words
    module Proxyable
      extend ActiveSupport::Concern

      def proxy_database
        raise StandardError, "Please set the #proxy_database_method" if self.class.proxy_database_method.nil?
        @proxy_database ||= self.class.prepare_database(self.send(self.class.proxy_database_method))
      end

      module ClassMethods


        # Define a collection that will use the base model for the database connection
        # details.
        def proxy_for(assoc_name, options = {})
          db_method = options[:database_method] || "proxy_database"
          options[:class_name] ||= assoc_name.to_s.singularize.camelize
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{assoc_name}
              @#{assoc_name} ||= CouchRest::Model::Proxyable::ModelProxy.new(::#{options[:class_name]}, self, self.class.to_s.underscore, #{db_method})
            end
          EOS
        end

        # Tell this model which other model to use a base for the database
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
          proxy_update(@model.get(id, @database))
        end
        alias :find :get

        protected

        def create_view_methods
          model.design_docs.each do |doc|
            doc.view_names.each do |name|
              class_eval <<-EOS, __FILE__, __LINE__ + 1
                def self.#{name}(opts = {})
                  #{name}({:proxy => self}.merge(opts))
                end
                def self.find_#{name}(*key)
                  #{name}.key(*key).first()
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

      end
    end
  end
end
