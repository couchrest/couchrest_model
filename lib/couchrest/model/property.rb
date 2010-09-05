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
          # Assume provided as a Hash where key is index!
          data = value
          value = [ ]
          data.keys.sort.each do |k|
            value << data[k]
          end
        elsif !value.is_a?(Array)
          raise "Expecting an array or keyed hash for property #{parent.class.name}##{self.name}"
        end
        arr = value.collect { |data| cast_value(parent, data) }
        # allow casted_by calls to be passed up chain by wrapping in CastedArray
        value = type_class != String ? CastedArray.new(arr, self) : arr
        value.casted_by = parent if value.respond_to?(:casted_by)
      elsif !value.nil?
        value = cast_value(parent, value)
      end
      value
    end

    # Cast an individual value, not an array
    def cast_value(parent, value)
      raise "An array inside an array cannot be casted, use CastedModel" if value.is_a?(Array)
      value = typecast_value(value, self)
      associate_casted_value_to_parent(parent, value)
    end

    def default_value
      return if default.nil?
      if default.class == Proc
        default.call
      else
        Marshal.load(Marshal.dump(default))
      end
    end

    private

      def associate_casted_value_to_parent(parent, value)
        value.casted_by = parent if value.respond_to?(:casted_by)
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
        @init_method        = options[:init_method] ? options.delete(:init_method) : 'new'
        @options            = options
      end

  end
end
