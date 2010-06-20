module CouchRest
  module Model
    module Attributes

      ## Support for handling attributes
      # 
      # This would be better in the properties file, but due to scoping issues
      # this is not yet possible.
      #

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

      # Takes a hash as argument, and applies the values by using writer methods
      # for each key. Raises a NoMethodError if the corresponding methods are
      # missing. In case of error, no attributes are changed.
      def update_attributes(hash)
        update_attributes_without_saving hash
        save
      end

      private

      def directly_set_attributes(hash)
        hash.each do |attribute_name, attribute_value|
          if self.respond_to?("#{attribute_name}=")
            self.send("#{attribute_name}=", hash.delete(attribute_name))
          end
        end
      end

      def directly_set_read_only_attributes(hash)
        property_list = self.properties.map{|p| p.name}
        hash.each do |attribute_name, attribute_value|
          next if self.respond_to?("#{attribute_name}=")
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
        property_list = self.properties.map{|p| p.name}
        attrs.each do |attribute_name, attribute_value|
          raise NoMethodError, "Property #{attribute_name} not created" unless respond_to?("#{attribute_name}=") or property_list.include?(attribute_name)
        end      
      end

    end
  end
end

