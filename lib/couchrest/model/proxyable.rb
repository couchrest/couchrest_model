module CouchRest
  module Model
    # :nodoc: Because I like inventing words
    module Proxyable
      extend ActiveSupport::Concern

      module ClassMethods

        attr_reader :proxy_owner_method

        # Define a collection that will use the base model for the database connection
        # details.
        def proxy_for(assoc_name, options = {})
          db_method = options[:database_method] || "proxy_database"
          options[:class_name] ||= assoc_name.to_s.singularize.camelize
          attr_accessor :model_proxy
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{assoc_name}
              unless respond_to?('#{db_method}')
                raise "Missing ##{db_method} method for proxy"
              end
              @#{assoc_name} ||= CouchRest::Model::Proxyable::ModelProxy.new(::#{options[:class_name]}, self, self.class.to_s.underscore, #{db_method})
            end
          EOS
        end

        def proxied_by(model_name, options = {})
          raise "Model can only be proxied once or ##{model_name} already defined" if method_defined?(model_name) || !proxy_owner_method.nil?
          self.proxy_owner_method = model_name
          attr_accessor model_name
        end
      end

      class ModelProxy

        attr_reader :model, :owner, :owner_name, :database

        def initialize(model, owner, owner_name, database)
          @model      = model
          @owner      = owner
          @owner_name = owner_name
          @database   = database
        end

        # Base
        
        def new(*args)
          proxy_update(model.new(*args))
        end

        def build_from_database(doc = {})
          proxy_update(model.build_from_database(doc))
        end
        
        def method_missing(m, *args, &block)
          if has_view?(m)
            if model.respond_to?(m)
              return model.send(m, *args).proxy(self)
            else
              query = args.shift || {}
              return view(m, query, *args, &block)
            end
          elsif m.to_s =~ /^find_(by_.+)/
            view_name = $1
            if has_view?(view_name)
              return first_from_view(view_name, *args) 
            end
          end
          super
        end
        
        # DocumentQueries
        
        def all(opts = {}, &block)
          proxy_update_all(@model.all({:database => @database}.merge(opts), &block))
        end
        
        def count(opts = {})
          @model.count({:database => @database}.merge(opts))
        end
        
        def first(opts = {})
          proxy_update(@model.first({:database => @database}.merge(opts)))
        end
        
        def last(opts = {})
          proxy_update(@model.last({:database => @database}.merge(opts)))
        end
        
        def get(id)
          proxy_update(@model.get(id, @database))
        end
        alias :find :get
        
        # Views
        
        def has_view?(view)
          @model.has_view?(view)
        end

        def view_by(*args)
          @model.view_by(*args)
        end
       
        def view(name, query={}, &block)
          proxy_update_all(@model.view(name, {:database => @database}.merge(query), &block))
        end
        
        def first_from_view(name, *args)
          # add to first hash available, or add to end
          (args.last.is_a?(Hash) ? args.last : (args << {}).last)[:database] = @database
          proxy_update(@model.first_from_view(name, *args))
        end
       
        # DesignDoc
        
        def design_doc
          @model.design_doc
        end
        
        def refresh_design_doc(db = nil)
          @model.refresh_design_doc(db || @database)
        end
        
        def save_design_doc(db = nil)
          @model.save_design_doc(db || @database)
        end


        protected

        # Update the document's proxy details, specifically, the fields that
        # link back to the original document.
        def proxy_update(doc)
          if doc
            doc.database = @database if doc.respond_to?(:database=)
            doc.model_proxy = self if doc.respond_to?(:model_proxy=)
            doc.send("#{owner_name}=", owner) if doc.respond_to?("#{owner_name}=")
          end
          doc
        end

        def proxy_update_all(docs)
          docs.each do |doc|
            proxy_update(doc)
          end
        end

      end
    end
  end
end
