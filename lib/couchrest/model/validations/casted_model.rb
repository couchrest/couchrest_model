module CouchRest
  module Model
    module Validations
      class CastedModelValidator < ActiveModel::EachValidator
        
        def validate_each(document, attribute, value)
          values = value.is_a?(Array) ? value : [value]
          return if values.collect {|doc| doc.nil? || doc.valid? }.all?
          error_options = { :value => value }
          error_options[:message] = options[:message] if options[:message]
          document.errors.add(attribute, :invalid, error_options)
        end
      end
    end
  end
end
