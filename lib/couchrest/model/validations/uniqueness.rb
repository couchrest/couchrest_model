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
          if options[:view].blank?
            attributes.each do |attribute|
              opts = merge_view_options(attribute)

              unless model.respond_to?(opts[:view_name])
                model.design do
                  view opts[:view_name], :allow_nil => true
                end
              end
            end
          end
        end

        def validate_each(document, attribute, value)
          opts = merge_view_options(attribute)

          values = opts[:keys].map{|k| document.send(k)}
          values = values.first if values.length == 1

          model = (document.respond_to?(:model_proxy) && document.model_proxy ? document.model_proxy : @model)
          # Determine the base of the search
          base = opts[:proxy].nil? ? model : document.instance_eval(opts[:proxy])

          unless base.respond_to?(opts[:view_name])
            raise "View #{document.class.name}.#{opts[:view_name]} does not exist for validation!"
          end

          rows = base.send(opts[:view_name], :key => values, :limit => 2, :include_docs => false).rows
          return if rows.empty?

          unless document.new?
            return if rows.find{|row| row.id == document.id}
          end

          if rows.length > 0
            opts = options.merge(:value => value)
            opts.delete(:scope) # Has meaning with I18n!
            document.errors.add(attribute, :taken, opts)
          end
        end

        private

        def merge_view_options(attr)
          keys = [attr]
          keys.unshift(*options[:scope]) unless options[:scope].nil?

          view_name = options[:view].nil? ? "by_#{keys.join('_and_')}" : options[:view]

          options.merge({:keys => keys, :view_name => view_name})
        end

      end

    end
  end
end
