# encoding: utf-8
module CouchRest
  module Model
    module Properties
      extend ActiveSupport::Concern

      included do
        extlib_inheritable_accessor(:properties) unless self.respond_to?(:properties)
        self.properties ||= []
        raise "You can only mixin Properties in a class responding to [] and []=, if you tried to mixin CastedModel, make sure your class inherits from Hash or responds to the proper methods" unless (method_defined?(:[]) && method_defined?(:[]=))
      end

      # Returns the Class properties
      #
      # ==== Returns
      # Array:: the list of properties for model's class
      def properties
        self.class.properties
      end

      # Returns the Class properties with their values
      #
      # ==== Returns
      # Array:: the list of properties with their values
      def properties_with_values
        props = {}
        properties.each { |property| props[property.name] = read_attribute(property.name) }
        props
      end

      # Read the casted value of an attribute defined with a property.
      #
      # ==== Returns
      # Object:: the casted attibutes value.
      def read_attribute(property)
        self[find_property!(property).to_s]
      end

      # Store a casted value in the current instance of an attribute defined
      # with a property.
      def write_attribute(property, value)
        prop = find_property!(property)
        self[prop.to_s] = prop.is_a?(String) ? value : prop.cast(self, value)
      end

      # write property, update dirty status
      def write_attribute_dirty(property, value)
        prop = find_property!(property)
        value = prop.is_a?(String) ? value : prop.cast(self, value)
        propname = prop.to_s
        attribute_will_change!(propname) if use_dirty? && self[propname] != value
        self[propname] = value
      end

      def []=(key,value)
        return super(key,value) unless use_dirty?

        has_changes = self.changed?
        if !has_changes && self.respond_to?(:get_unique_id)
          check_id_change = true
          old_id = get_unique_id
        end

        ret = super(key, value)

        if check_id_change
          # if we have set an attribute that results in the _id changing (unique_id),
          # force changed? to return true so that the record can be saved
          new_id = get_unique_id
          changed_attributes["_id"] = new_id if old_id != new_id
        end

        ret
      end

      # Takes a hash as argument, and applies the values by using writer methods
      # for each key. It doesn't save the document at the end. Raises a NoMethodError if the corresponding methods are
      # missing. In case of error, no attributes are changed.
      def update_attributes_without_saving(hash)
        # Remove any protected and update all the rest. Any attributes
        # which do not have a property will simply be ignored.
        attrs = remove_protected_attributes(hash)
        directly_set_attributes(attrs, :dirty => true)
      end
      alias :attributes= :update_attributes_without_saving

      # 'attributes' needed for Dirty
      alias :attributes :properties_with_values

      def find_property(property)
        property.is_a?(Property) ? property : self.class.properties.detect {|p| p.to_s == property.to_s}
      end

      # The following methods should be accessable by the Model::Base Class, but not by anything else!
      def apply_all_property_defaults
        return if self.respond_to?(:new?) && (new? == false)
        # TODO: cache the default object
        self.class.properties.each do |property|
          write_attribute(property, property.default_value)
        end
      end

      def prepare_all_attributes(doc = {}, options = {})
        apply_all_property_defaults
        if options[:directly_set_attributes]
          directly_set_read_only_attributes(doc)
        else
          doc = remove_protected_attributes(doc)
        end
        directly_set_attributes(doc) unless doc.nil?
      end

      def find_property!(property)
        prop = find_property(property)
        raise ArgumentError, "Missing property definition for #{property.to_s}" if prop.nil?
        prop
      end

      # Set all the attributes and return a hash with the attributes
      # that have not been accepted.
      def directly_set_attributes(hash, options = {})
        self.disable_dirty = !options[:dirty]
        ret = hash.reject do |attribute_name, attribute_value|
          if self.respond_to?("#{attribute_name}=")
            self.send("#{attribute_name}=", attribute_value)
            true
          elsif mass_assign_any_attribute # config option
            self[attribute_name] = attribute_value
            true
          else
            false
          end
        end
        self.disable_dirty = false
        ret
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


      module ClassMethods

        def property(name, *options, &block)
          opts = { }
          type = options.shift
          if type.class != Hash
            opts[:type] = type
            opts.merge!(options.shift || {})
          else
            opts.update(type)
          end
          existing_property = self.properties.find{|p| p.name == name.to_s}
          if existing_property.nil? || (existing_property.default != opts[:default])
            define_property(name, opts, &block)
          end
        end

        # Automatically set <tt>updated_at</tt> and <tt>created_at</tt> fields
        # on the document whenever saving occurs. CouchRest uses a pretty
        # decent time format by default. See Time#to_json
        def timestamps!
          class_eval <<-EOS, __FILE__, __LINE__
            property(:updated_at, Time, :read_only => true, :protected => true, :auto_validation => false)
            property(:created_at, Time, :read_only => true, :protected => true, :auto_validation => false)

            set_callback :save, :before do |object|
              write_attribute('updated_at', Time.now)
              write_attribute('created_at', Time.now) if object.new?
            end
          EOS
        end

        protected

          # This is not a thread safe operation, if you have to set new properties at runtime
          # make sure a mutex is used.
          def define_property(name, options={}, &block)
            # check if this property is going to casted
            type = options.delete(:type) || options.delete(:cast_as)
            if block_given?
              type = Class.new(Hash) do
                include CastedModel
              end
              if block.arity == 1 # Traditional, with options
                type.class_eval { yield type }
              else
                type.instance_exec(&block)
              end
              type = [type] # inject as an array
            end
            property = Property.new(name, type, options)
            create_property_getter(property)
            create_property_setter(property) unless property.read_only == true
            if property.type_class.respond_to?(:validates_casted_model)
              validates_casted_model property.name
            end
            properties << property
            property
          end

          # defines the getter for the property (and optional aliases)
          def create_property_getter(property)
            # meth = property.name
            class_eval <<-EOS, __FILE__, __LINE__ + 1
              def #{property.name}
                read_attribute('#{property.name}')
              end
            EOS

            if ['boolean', TrueClass.to_s.downcase].include?(property.type.to_s.downcase)
              class_eval <<-EOS, __FILE__, __LINE__
                def #{property.name}?
                  value = read_attribute('#{property.name}')
                  !(value.nil? || value == false)
                end
              EOS
            end

            if property.alias
              class_eval <<-EOS, __FILE__, __LINE__ + 1
                alias #{property.alias.to_sym} #{property.name.to_sym}
              EOS
            end
          end

          # defines the setter for the property (and optional aliases)
          def create_property_setter(property)
            property_name = property.name
            class_eval <<-EOS
              def #{property_name}=(value)
                write_attribute_dirty('#{property_name}', value)
              end
            EOS

            if property.alias
              class_eval <<-EOS
                alias #{property.alias.to_sym}= #{property_name.to_sym}=
              EOS
            end
          end

      end # module ClassMethods

    end
  end
end

