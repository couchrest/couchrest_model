
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
    module Design
      extend ActiveSupport::Concern

      module ClassMethods

        def design(*args, &block)
        

        end

      end

      # 
      module DesignMethods


        def view(*args)

        end

      end
    end
  end
end
