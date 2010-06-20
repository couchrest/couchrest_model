module CouchRest
  module Model
    module Validations
      class CastedModelValidator < ActiveModel::EachValidator
        
        def validate_each(document, attribute, value)
          values = value.is_a?(Array) ? value : [value]
          return if values.collect {|doc| doc.nil? || doc.valid? }.all?
          document.errors.add(attribute, :invalid, :default => options[:message], :value => value)
        end
      end
    end
  end
end
