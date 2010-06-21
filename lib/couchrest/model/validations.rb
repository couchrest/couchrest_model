# encoding: utf-8

require "couchrest/model/validations/casted_model"
require "couchrest/model/validations/uniqueness"

I18n.load_path << File.join(
  File.dirname(__FILE__), "validations", "locale", "en.yml"
)

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
        
        # Validates if the field is unique for this type of document. Automatically creates
        # a view if one does not already exist and performs a search for all matching
        # documents.
        #
        # Example:
        #
        #   class Person < CouchRest::Model::Base
        #     property :title, String
        # 
        #     validates_uniqueness_of :title
        #   end
        #
        # Asside from the standard options, a +:proxy+ parameter is also accepted if you would 
        # like to call a method on the document on which the view should be performed.
        #
        # Examples:
        #
        #   # Same as not including proxy:
        #   validates_uniqueness_of :title, :proxy => 'class'
        #
        #   # Person#company.people provides a proxy object for people
        #   validates_uniqueness_of :title, :proxy => 'company.people'
        #
        def validates_uniqueness_of(*args)
          validates_with(UniquenessValidator, _merge_attributes(args))
        end
      end

    end
  end
end
