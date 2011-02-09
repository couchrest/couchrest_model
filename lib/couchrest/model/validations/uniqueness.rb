# encoding: utf-8

module CouchRest
  module Model
    module Validations
      
      # Validates if a field is unique 
      class UniquenessValidator < ActiveModel::EachValidator

        # Ensure we have a class available so we can check for a usable view
        # or add one if necessary.
        def setup(model)
          @model = model
        end

        def validate_each(document, attribute, value)
          view_name = options[:view].nil? ? "by_#{attribute}" : options[:view]
          model = document.model_proxy || @model
          # Determine the base of the search
          base = options[:proxy].nil? ? model : document.instance_eval(options[:proxy])

          if base.respond_to?(:has_view?) && !base.has_view?(view_name)
            raise "View #{document.class.name}.#{options[:view]} does not exist!" unless options[:view].nil?
            model.view_by attribute
          end

          docs = base.view(view_name, :key => value, :limit => 2, :include_docs => false)['rows']
          return if docs.empty?

          unless document.new?
            return if docs.find{|doc| doc['id'] == document.id}
          end
          
          if docs.length > 0
            document.errors.add(attribute, :taken, :default => options[:message], :value => value)
          end
        end

      end

    end
  end
end
