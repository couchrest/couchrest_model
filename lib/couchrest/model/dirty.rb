# encoding: utf-8

I18n.load_path << File.join(
  File.dirname(__FILE__), "validations", "locale", "en.yml"
)

module CouchRest
  module Model

    # This applies to both Model::Base and Model::CastedModel
    module Dirty
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Dirty
      end

      def couchrest_attribute_will_change!(attr)
        return if attr.nil?
        self.send("#{attr}_will_change!")
        if pkey = casted_by_attribute
          @casted_by.couchrest_attribute_will_change!(pkey)
        end
      end
      
      def couchrest_parent_will_change!
        @casted_by.couchrest_attribute_will_change!(casted_by_attribute) if @casted_by
      end

      private
      
      # return the attribute name this object is referenced by in the parent
      def casted_by_attribute
        return nil unless @casted_by
        attr = @casted_by.attributes
        attr.keys.detect { |k| attr[k] == self }
      end

    end
  end
end
