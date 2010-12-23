module CouchRest
  module Model
    module PropertyProtection
      extend ActiveSupport::Concern

      # Property protection from mass assignment to CouchRest::Model properties
      #
      # Protected methods will be removed from
      #  * new
      #  * update_attributes
      #  * upate_attributes_without_saving
      #  * attributes=
      #
      # There are two modes of protection
      #  1) Declare accessible poperties, and assume all unspecified properties are protected
      #    property :name,  :accessible => true
      #    property :admin                      # this will be automatically protected
      #
      #  2) Declare protected properties, and assume all unspecified properties are accessible
      #    property :name                       # this will not be protected
      #    property :admin, :protected => true
      #
      #  3) Mix and match, and assume all unspecified properties are protected.
      #    property :name,  :accessible => true
      #    property :admin, :protected  => true # ignored
      #    property :phone                      # this will be automatically protected
      #
      #  Note: the timestamps! method protectes the created_at and updated_at properties


      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def accessible_properties
          props = properties.select { |prop| prop.options[:accessible] }
          if props.empty?
            props = properties.select { |prop| !prop.options[:protected] }
          end
          props
        end

        def protected_properties
          accessibles = accessible_properties
          properties.reject { |prop| accessibles.include?(prop) }
        end
      end

      def accessible_properties
        self.class.accessible_properties
      end

      def protected_properties
        self.class.protected_properties
      end

      # Return a new copy of the attributes hash with protected attributes
      # removed.
      def remove_protected_attributes(attributes)
        protected_names = protected_properties.map { |prop| prop.name }
        return attributes if protected_names.empty? or attributes.nil?

        attributes.reject do |property_name, property_value|
          protected_names.include?(property_name.to_s)
        end
      end

    end
  end
end
