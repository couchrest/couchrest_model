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
          keys = [attribute]
          unless options[:scope].nil?
            keys = (options[:scope].is_a?(Array) ? options[:scope] : [options[:scope]]) + keys
          end
          values = keys.map{|k| document.send(k)}
          values = values.first if values.length == 1

          view_name = options[:view].nil? ? "by_#{keys.join('_and_')}" : options[:view]

          model = (document.respond_to?(:model_proxy) && document.model_proxy ? document.model_proxy : @model)
          # Determine the base of the search
          base = options[:proxy].nil? ? model : document.instance_eval(options[:proxy])

          if base.respond_to?(:has_view?) && !base.has_view?(view_name)
            raise "View #{document.class.name}.#{options[:view]} does not exist!" unless options[:view].nil?
            keys << {:allow_nil => true}
            model.view_by(*keys)
          end

          rows = base.view(view_name, :key => values, :limit => 2, :include_docs => false)['rows']
          return if rows.empty?

          unless document.new?
            return if rows.find{|row| row['id'] == document.id}
          end

          if rows.length > 0
            opts = options.merge(:value => value)
            opts.delete(:scope) # Has meaning with I18n!
            document.errors.add(attribute, :taken, opts)
          end
        end

      end

    end
  end
end
