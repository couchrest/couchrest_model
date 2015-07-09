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
      include ActiveModel::Validations

      # Determine if the document is valid.
      #
      # @example Is the document valid?
      #   person.valid?
      #
      # @example Is the document valid in a context?
      #   person.valid?(:create)
      #
      # @param [ Symbol ] context The optional validation context.
      #
      # @return [ true, false ] True if valid, false if not.
      #
      def valid?(context = nil)
        super context ? context : (new? ? :create : :update)
      end

      module ClassMethods

        # Validates the associated casted model. This method should not be
        # used within your code as it is automatically included when a CastedModel
        # is used inside the model.
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
        # Asside from the standard options, you can specify the name of the view you'd like
        # to use for the search inside the +:view+ option. The following example would search
        # for the code in side the +all+ view, useful for when +unique_id+ is used and you'd
        # like to check before receiving a CouchRest::Conflict error:
        #
        #   validates_uniqueness_of :code, :view => 'all'
        #
        # A +:proxy+ parameter is also accepted if you would 
        # like to call a method on the document on which the view should be performed.
        #
        # For Example:
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
