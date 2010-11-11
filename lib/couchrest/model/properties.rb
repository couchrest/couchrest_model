# encoding: utf-8
require 'set'
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

      def properties_with_values
        props = {}
        properties.each { |property| props[property.name] = read_attribute(property.name) }
        props
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
            create_property_alias(property) if property.alias
            if property.type_class.respond_to?(:validates_casted_model)
              validates_casted_model property.name
            end
            properties << property
            property
          end

          def create_property_alias(property)
            class_eval <<-EOS, __FILE__, __LINE__ + 1
              def #{property.alias.to_s}
                #{property.name}
              end
            EOS
          end

      end # module ClassMethods
    end
  end
end

