# encoding: utf-8
module CouchRest
  module Model
    module Properties

      class IncludeError < StandardError; end

      def self.included(base)
        base.class_eval <<-EOS, __FILE__, __LINE__ + 1
            extlib_inheritable_accessor(:properties) unless self.respond_to?(:properties)
            self.properties ||= []
        EOS
        base.extend(ClassMethods)
        raise CouchRest::Mixins::Properties::IncludeError, "You can only mixin Properties in a class responding to [] and []=, if you tried to mixin CastedModel, make sure your class inherits from Hash or responds to the proper methods" unless (base.new.respond_to?(:[]) && base.new.respond_to?(:[]=))
      end

      # Returns the Class properties
      #
      # ==== Returns
      # Array:: the list of properties for model's class
      def properties
        self.class.properties
      end

      def read_attribute(property)
        prop = find_property!(property)
        self[prop.to_s]
      end

      def write_attribute(property, value)
        prop = find_property!(property)
        self[prop.to_s] = prop.cast(self, value)
      end

      def apply_all_property_defaults
        return if self.respond_to?(:new?) && (new? == false)
        # TODO: cache the default object
        self.class.properties.each do |property|
          write_attribute(property, property.default_value)
        end
      end

      private
      def find_property!(property)
        prop = property.is_a?(Property) ? property : self.class.properties.detect {|p| p.to_s == property.to_s}
        raise ArgumentError, "Missing property definition for #{property.to_s}" unless prop
        prop
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
              type.class_eval { yield type }
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
                write_attribute('#{property_name}', value)
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
