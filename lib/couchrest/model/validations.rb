# encoding: utf-8

require "couchrest/model/validations/casted_model"

module CouchRest
  module Model

    # Validations may be applied to both Model::Base and Model::CastedModel
    module Validations
      extend ActiveSupport::Concern
      included do
        include ActiveModel::Validations
      end
      

      module ClassMethods
        
        # Validates the associated casted model. This method should not be 
        # used within your code as it is automatically included when a CastedModel
        # is used inside the model.
        #
        def validates_casted_model(*args)
          validates_with(CastedModelValidator, _merge_attributes(args))
        end
        
        # TODO: Here will lie validates_uniqueness_of
        
      end

    end
  end
end
