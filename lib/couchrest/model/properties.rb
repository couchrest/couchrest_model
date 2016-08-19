# encoding: utf-8
module CouchRest
  module Model
    module Properties
      extend ActiveSupport::Concern

      included do
        class_attribute(:properties) unless self.respond_to?(:properties)
        class_attribute(:properties_by_name) unless self.respond_to?(:properties_by_name)
        self.properties ||= []
        self.properties_by_name ||= {}
      end

      # Provide an attribute hash ready to be sent to CouchDB but with
      # all the nil attributes removed.
      def as_couch_json
        super.delete_if{|k,v| v.nil?}
      end

      # Read the casted value of an attribute defined with a property.
      def read_attribute(property)
        self[find_property!(property).to_s]
      end

      # Store a casted value in the current instance of an attribute defined
      # with a property.
      def write_attribute(property, value)
        prop = find_property!(property)
        value = prop.cast(self, value)
        self[prop.name] = value
      end

      # Returns a hash of this object's attributes with a defined property.
      # This is effectively an accessor to the underlying CouchRest 
      # attributes hash.
      def read_attributes
        @_attributes
      end
      alias :attributes :read_attributes

      # Takes a hash as argument, and applies the values by using writer
      # methods respecting protected properties.
      def write_attributes(hash)
        attrs = remove_protected_attributes(hash)
        directly_set_attributes(attrs)
        self
      end
      alias :attributes= :write_attributes

      # Takes the provided attribute hash and sets all properties, assuming
      # that the data is from a trusted source, such as the database.
      def write_all_attributes(attrs = {})
        directly_set_read_only_attributes(attrs)
        directly_set_attributes(attrs, true)
        self
      end

      protected

      def find_property(property)
        property.is_a?(Property) ? property : self.class.properties_by_name[property.to_s]
      end

      def find_property!(property)
        find_property(property) or
          raise ArgumentError, "Missing property definition for #{property.to_s}"
      end

      def write_attributes_for_initialization(attrs = {}, opts = {})
        apply_all_property_defaults
        if opts[:write_all_attributes]
          # Assume coming from a database, so we clear change information after
          write_all_attributes(attrs)
          clear_changes_information
        else
          # Not from a persisted source, clear the change data in advance and do
          # not set protected or read-only attributes.
          clear_changes_information
          write_attributes(attrs)
        end
      end

      # Apply each property's default value to the attributes. This should
      # only ever be called on initialization.
      def apply_all_property_defaults
        self.class.properties.each do |property|
          write_attribute(property, property.default_value)
        end
      end

      # Set all the attributes and return a hash with the attributes
      # that have not been accepted.
      def directly_set_attributes(hash, mass_assign = false)
        return if hash.nil?

        multi_parameter_attributes = []

        hash.reject do |key, value|
          if key.to_s.include?("(")
            multi_parameter_attributes << [ key, value ]
            false
          elsif self.respond_to?("#{key}=")
            self.send("#{key}=", value) 
          elsif mass_assign || mass_assign_any_attribute
            self[key] = value
          end
        end

        # Handle attributes provided in an embedded object format, such
        # as a web-form.
        unless multi_parameter_attributes.empty?
          assign_multiparameter_attributes(multi_parameter_attributes, hash)
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

      def assign_multiparameter_attributes(pairs, hash)
        execute_callstack_for_multiparameter_attributes(
          extract_callstack_for_multiparameter_attributes(pairs), hash
        )
      end
      def execute_callstack_for_multiparameter_attributes(callstack, hash)
        callstack.each do |name, values_with_empty_parameters|
          if self.respond_to?("#{name}=")
            casted_attrib = send("#{name}=", values_with_empty_parameters) 
            unless casted_attrib.is_a?(Hash)
              hash.reject { |key, value| key.include?(name.to_s)}
            end
          end
        end
        hash
      end

      def extract_callstack_for_multiparameter_attributes(pairs)
        attributes = { }

        pairs.each do |pair|
          multiparameter_name, value = pair
          attribute_name = multiparameter_name.split("(").first
          attributes[attribute_name] = {} unless attributes.include?(attribute_name)
          attributes[attribute_name][find_parameter_name(multiparameter_name)] ||= value
        end
        attributes
      end

      def find_parameter_name(multiparameter_name)
        position = multiparameter_name.scan(/\(([0-9]*).*\)/).first.first.to_i
        {1 => :year, 2 => :month, 3 => :day, 4 => :hour, 5 => :min, 6 => :sec}[position]
      end

      module ClassMethods

        def property(name, *options, &block)
          raise "Invalid property definition, '#{name}' already used for CouchRest Model type field" if name.to_s == model_type_key.to_s && CouchRest::Model::Base >= self
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
        # on the document whenever saving occurs.
        # 
        # These properties are casted as Time objects, so they should always
        # be set to UTC.
        def timestamps!
          property(:updated_at, Time, :read_only => true, :protected => true, :auto_validation => false)
          property(:created_at, Time, :read_only => true, :protected => true, :auto_validation => false)

          set_callback :save, :before do |object|
            write_attribute('updated_at', Time.now)
            write_attribute('created_at', Time.now) if object.new?
          end
        end

        protected

          # This is not a thread safe operation, if you have to set new properties at runtime
          # make sure a mutex is used.
          def define_property(name, options = {}, &block)
            property = Property.new(name, options, &block)
            create_property_getter(property)
            create_property_setter(property) unless property.read_only == true

            if property.type.respond_to?(:validates_casted_model)
              validates_casted_model property.name
            end

            # Dirty!
            create_dirty_property_methods(property)

            properties << property
            properties_by_name[property.to_s] = property
            property
          end

          # defines the getter for the property (and optional aliases)
          def create_property_getter(property)
            define_method(property.name) do
              read_attribute(property.name)
            end

            if ['boolean', TrueClass.to_s.downcase].include?(property.type.to_s.downcase)
              define_method("#{property.name}?") do
                value = read_attribute(property.name)
                !(value.nil? || value == false)
              end
            end

            if property.alias
              alias_method(property.alias, property.name.to_sym)
            end
          end

          # defines the setter for the property (and optional aliases)
          def create_property_setter(property)
            name = property.name

            define_method("#{name}=") do |value|
              write_attribute(name, value)
            end

            if property.alias
              alias_method "#{property.alias}=", "#{name}="
            end
          end

      end # module ClassMethods

    end
  end
end

