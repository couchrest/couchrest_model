
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
        def design(*args, &block)
          mapper = DesignMapper.new(self)
          mapper.create_view_method(:all)

          mapper.instance_eval(&block) if block_given?
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

      # 
      class DesignMapper

        attr_accessor :model

        def initialize(model)
          self.model = model
        end

        # Define a view and generate a method that will provide a new 
        # View instance when requested.
        def view(name, opts = {})
          View.create(model, name, opts)
          create_view_method(name)
        end

        def create_view_method(name)
          model.class_eval <<-EOS, __FILE__, __LINE__ + 1
            def self.#{name}(opts = {})
              CouchRest::Model::Designs::View.new(self, opts, '#{name}')
            end
          EOS
        end

      end
    end
  end
end
