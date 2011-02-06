
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

        def design(*args, &block)
          mapper = DesignMapper.new(self)
          mapper.instance_eval(&block)

          req_design_doc_refresh
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
