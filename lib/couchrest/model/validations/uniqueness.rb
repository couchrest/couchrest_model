# encoding: urf-8

module CouchRest
  module Model
    module Validations
      
      # Validates if a field is unique 
      class UniquenessValidator < ActiveModel::EachValidator

        # Ensure we have a class available so we can check for a usable view
        # or add one if necessary.
        def setup(klass)
          @klass = klass
        end


        def validate_each(document, attribute, value)
          unless @klass.has_view?("by_#{attribute}")
            @klass.view_by attribute
          end

          # Determine the base of the search
          base = options[:proxy].nil? ? @klass : document.instance_eval(options[:proxy])

          docs = base.view("by_#{attribute}", :key => value, :limit => 2, :include_docs => false)['rows']
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
