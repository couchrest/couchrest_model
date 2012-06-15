# encoding: utf-8
module CouchRest::Model
  class Property

    include ::CouchRest::Model::Typecast

    attr_reader :name, :type, :type_class, :read_only, :alias, :default, :casted, :init_method, :options

    # Attribute to define.
    # All Properties are assumed casted unless the type is nil.
    def initialize(name, type = nil, options = {})
      @name = name.to_s
      @casted = true
      parse_type(type)
      parse_options(options)
      self
    end

    def to_s
      name
    end

    # Cast the provided value using the properties details.
    def cast(parent, value)
      return value unless casted
      if type.is_a?(Array)
        if value.nil?
          value = []
        elsif [Hash, HashWithIndifferentAccess].include?(value.class)
          # Assume provided as a params hash where key is index
          value = parameter_hash_to_array(value)
        elsif !value.is_a?(Array)
          raise "Expecting an array or keyed hash for property #{parent.class.name}##{self.name}"
        end
        arr = value.collect { |data| cast_value(parent, data) }
        # allow casted_by calls to be passed up chain by wrapping in CastedArray
        CastedArray.new(arr, self, parent)
      elsif (type == Object || type == Hash) && (value.is_a?(Hash))
        # allow casted_by calls to be passed up chain by wrapping in CastedHash
        CastedHash[value, self, parent]
      elsif !value.nil?
        cast_value(parent, value)
      end
    end

    # Cast an individual value
    def cast_value(parent, value)
      value = typecast_value(parent, self, value)
      associate_casted_value_to_parent(parent, value)
    end

    def default_value
      return if default.nil?
      if default.class == Proc
        default.call
      else
        # TODO identify cause of mutex errors
        Marshal.load(Marshal.dump(default))
      end
    end

    # Initialize a new instance of a property's type ready to be
    # used. If a proc is defined for the init method, it will be used instead of 
    # a normal call to the class.
    def build(*args)
      raise StandardError, "Cannot build property without a class" if @type_class.nil?

      if @init_method.is_a?(Proc)
        @init_method.call(*args)
      else
        @type_class.send(@init_method, *args)
      end
    end

    private

      def parameter_hash_to_array(source)
        value = [ ]
        source.keys.each do |k|
          value[k.to_i] = source[k]
        end
        value.compact
      end

      def associate_casted_value_to_parent(parent, value)
        value.casted_by = parent if value.respond_to?(:casted_by)
        value.casted_by_property = self if value.respond_to?(:casted_by_property)
        value
      end

      def parse_type(type)
        if type.nil?
          @casted = false
          @type = nil
          @type_class = nil
        else
          base = type.is_a?(Array) ? type.first : type
          base = Object if base.nil?
          raise "Defining a property type as a #{type.class.name.humanize} is not supported in CouchRest Model!" if base.class != Class
          @type_class = base
          @type = type
        end
      end

      def parse_options(options)
        @validation_format  = options.delete(:format)     if options[:format]
        @read_only          = options.delete(:read_only)  if options[:read_only]
        @alias              = options.delete(:alias)      if options[:alias]
        @default            = options.delete(:default)    unless options[:default].nil?
        @init_method        = options.delete(:init_method) || 'new'
        @options            = options
      end

  end
end
