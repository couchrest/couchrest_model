module CouchRest
  module Model
    ReadOnlyPropertyError = Class.new(StandardError)

    # Attributes Suffixes provide methods from ActiveModel
    # to hook into. See methods such as #attribute= and
    # #attribute? for their implementation
    AttributeMethodSuffixes = ['', '=', '?']

    module Attributes
      extend ActiveSupport::Concern

      included do
        include ActiveModel::AttributeMethods
        attribute_method_suffix *AttributeMethodSuffixes
      end

      module ClassMethods
        def attributes
          properties.map {|prop| prop.name}
        end
      end

      def initialize(*args)
        self.class.attribute_method_suffix *AttributeMethodSuffixes
        super
      end

      def attributes
        self.class.attributes
      end

      ## Reads the attribute value.
      # Assuming you have a property :title this would be called
      # by `model_instance.title`
      def attribute(name)
        read_attribute(name)
      end

      ## Sets the attribute value.
      # Assuming you have a property :title this would be called
      # by `model_instance.title = 'hello'`
      def attribute=(name, value)
        raise ReadOnlyPropertyError, 'read only property' if find_property!(name).read_only
        write_attribute(name, value)
      end

      ## Tests for both presence and truthiness of the attribute.
      # Assuming you have a property :title # this would be called
      # by `model_instance.title?`
      def attribute?(name)
        value = read_attribute(name)
        !(value.nil? || value == false)
      end

      ## Support for handling attributes
      #
      # This would be better in the properties file, but due to scoping issues
      # this is not yet possible.
      def prepare_all_attributes(doc = {}, options = {})
        apply_all_property_defaults
        if options[:directly_set_attributes]
          directly_set_read_only_attributes(doc)
        else
          remove_protected_attributes(doc)
        end
        directly_set_attributes(doc) unless doc.nil?
      end

      # Takes a hash as argument, and applies the values by using writer methods
      # for each key. It doesn't save the document at the end. Raises a NoMethodError if the corresponding methods are
      # missing. In case of error, no attributes are changed.
      def update_attributes_without_saving(hash)
        # Remove any protected and update all the rest. Any attributes
        # which do not have a property will simply be ignored.
        attrs = remove_protected_attributes(hash)
        directly_set_attributes(attrs)
      end
      alias :attributes= :update_attributes_without_saving

      def read_attribute(property)
        prop = find_property!(property)
        self[prop.to_s]
      end

      def write_attribute(property, value)
        prop = find_property!(property)
        self[prop.to_s] = prop.cast(self, value)
      end

      private

      def read_only_attributes
        properties.select { |prop| prop.read_only }.map { |prop| prop.name }
      end

      def directly_set_attributes(hash)
        r_o_a = read_only_attributes
        hash.each do |attribute_name, attribute_value|
          next if r_o_a.include? attribute_name
          if self.respond_to?("#{attribute_name}=")
            self.send("#{attribute_name}=", hash.delete(attribute_name))
          end
        end
      end

      def directly_set_read_only_attributes(hash)
        r_o_a = read_only_attributes
        property_list = attributes
        hash.each do |attribute_name, attribute_value|
          next unless r_o_a.include? attribute_name
          if property_list.include?(attribute_name)
            write_attribute(attribute_name, hash.delete(attribute_name))
          end
        end
      end

      def set_attributes(hash)
        attrs = remove_protected_attributes(hash)
        directly_set_attributes(attrs)
      end

      def check_properties_exist(attrs)
        property_list = attributes
        attrs.each do |attribute_name, attribute_value|
          raise NoMethodError, "Property #{attribute_name} not created" unless respond_to?("#{attribute_name}=") or property_list.include?(attribute_name)
        end
      end
    end
  end
end

