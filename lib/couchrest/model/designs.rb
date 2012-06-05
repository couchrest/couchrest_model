
#### NOTE Work in progress! Not yet used!

module CouchRest
  module Model

    # A design block in CouchRest Model groups together the functionality of CouchDB's
    # design documents in a simple block definition.
    #
    #   class Person < CouchRest::Model::Base
    #     property :name
    #     timestamps!
    #
    #     design do
    #       view :by_name
    #     end
    #   end
    #
    module Designs
      extend ActiveSupport::Concern


      module ClassMethods

        # Add views and other design document features
        # to the current model.
        def design(prefix = nil, &block)
          mapper = DesignMapper.new(self, prefix)
          mapper.instance_eval(&block) if block_given?
          # Create an 'all' view, using the previous settings.
          mapper.view :all if prefix.nil?
        end

        # Override the default page pagination value:
        #
        #   class Person < CouchRest::Model::Base
        #     paginates_per 10
        #   end
        #
        def paginates_per(val)
          @_default_per_page = val
        end

        # The models number of documents to return
        # by default when performing pagination.
        # Returns 25 unless explicitly overridden via <tt>paginates_per</tt>
        def default_per_page
          @_default_per_page || 25
        end

      end


      class DesignMapper

        # Basic mapper attributes
        attr_accessor :model, :method, :prefix

        # Temporary variable storing the design doc
        attr_accessor :design_doc

        def initialize(model, prefix = nil)
          self.model  = model
          self.prefix = prefix
          self.method = (prefix ? "#{prefix}_" : '') + 'design_doc'

          # Create design doc method in model, then call it so we have a copy
          create_design_doc_method
          self.design_doc = model.send(method)

          # Some defaults
          design_doc.auto_update = model.auto_update_design_doc
        end

        def disable_auto_update
          design_doc.auto_update = false
        end

        def enable_auto_update
          design_doc.auto_update = true
        end

        # Add the specified view to the design doc the definition was made in
        # and create quick access methods in the model.
        def view(name, opts = {})
          View.define(model, design_doc, name, opts)
          create_view_method(name)
        end

        # Really simple design function that allows a filter
        # to be added. Filters are simple functions used when listening
        # to the _changes feed.
        #
        # No methods are created here, the design is simply updated.
        # See the CouchDB API for more information on how to use this.
        def filter(name, function)
          filters = (design_doc['filters'] ||= {})
          filters[name.to_s] = function
        end

        # Convenience wrapper to access model's type key option.
        def model_type_key
          model.model_type_key
        end

        protected

        def create_design_doc_method
          model.class_eval <<-EOS, __FILE__, __LINE__ + 1
            def self.#{method}
              @_#{method} ||= ::CouchRest::Model::Designs::Design.new(self, #{prefix ? '"'+prefix.to_s+'"' : 'nil'})
            end
          EOS
        end

        def create_view_method(name, prefix = nil)
          prefix = prefix ? "#{prefix}_" : ''
          model.class_eval <<-EOS, __FILE__, __LINE__ + 1
            def self.#{name}(opts = {})
              #{method}.view('#{name}', opts)
            end
            def self.find_#{name}(*key)
              #{name}.key(*key).first()
            end
          EOS
        end

      end
    end
  end
end
