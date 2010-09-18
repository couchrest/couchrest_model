module CouchRest
  module Model
    module AttributeProtection
      extend ActiveSupport::Concern

      # Attribute protection from mass assignment to CouchRest::Model properties
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
      #    property :admin, :protected  => true
      #    property :phone                      # this will be automatically protected
      #
      #  Note: the timestamps! method protectes the created_at and updated_at properties


      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def accessible_properties
          properties.select { |prop| prop.options[:accessible] }
        end

        def protected_properties
          properties.select { |prop| prop.options[:protected] }
        end
      end

      def accessible_properties
        self.class.accessible_properties
      end

      def protected_properties
        self.class.protected_properties
      end

      def remove_protected_attributes(attributes)
        protected_names = properties_to_remove_from_mass_assignment.map { |prop| prop.name }
        return attributes if protected_names.empty?

        attributes.reject! do |property_name, property_value|
          protected_names.include?(property_name.to_s)
        end if attributes

        attributes || {}
      end

      private

      def properties_to_remove_from_mass_assignment
        to_remove = protected_properties

        unless accessible_properties.empty?
          to_remove += properties.reject { |prop| prop.options[:accessible] }
        end

        to_remove
      end
    end
  end
end
