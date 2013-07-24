# encoding: utf-8
module CouchRest::Model
  class Property

    include ::CouchRest::Model::Typecast

    attr_reader :name, :type, :array, :read_only, :alias, :default, :casted, :init_method, :options, :allow_blank

    # Attribute to define.
    # All Properties are assumed casted unless the type is nil.
    def initialize(name, options = {}, &block)
      @name = name.to_s
      parse_options(options)
      parse_type(options, &block)
      self
    end

    def to_s
      name
    end
    
    def to_sym
      @_sym_name ||= name.to_sym
    end

    # Cast the provided value using the properties details.
    def cast(parent, value)
      return value unless casted
      if array
        if value.nil?
          value = []
        elsif [Hash, HashWithIndifferentAccess].include?(value.class)
          # Assume provided as a params hash where key is index
          value = parameter_hash_to_array(value)
        elsif !value.is_a?(Array)
          raise "Expecting an array or keyed hash for property #{parent.class.name}##{self.name}"
        end
        arr = value.collect { |data| cast_value(parent, data) }
        arr.reject!{ |data| data.nil? } unless allow_blank
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
      if !allow_blank && value.to_s.empty?
        nil
      else
        value = typecast_value(parent, self, value)
        associate_casted_value_to_parent(parent, value)
      end
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
      raise StandardError, "Cannot build property without a class" if @type.nil?

      if @init_method.is_a?(Proc)
        @init_method.call(*args)
      else
        @type.send(@init_method, *args)
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

      def parse_type(options, &block)
        set_type_from_block(&block) if block_given?
        if @type.nil?
          @casted = false
        else
          @casted = true
          if @type.is_a?(Array)
            @type  = @type.first || Object
            @array = true
          end
          raise "Defining a property type as a #{@type.class.name.humanize} is not supported in CouchRest Model!" if @type.class != Class
        end
      end

      def parse_options(options)
        @type               = options.delete(:type) || options.delete(:cast_as)
        @array              = !!options.delete(:array)
        @validation_format  = options.delete(:format)      if options[:format]
        @read_only          = options.delete(:read_only)   if options[:read_only]
        @alias              = options.delete(:alias)       if options[:alias]
        @default            = options.delete(:default)     unless options[:default].nil?
        @init_method        = options.delete(:init_method) || 'new'
        @allow_blank        = options[:allow_blank].nil? ? true : options.delete(:allow_blank)
        @options            = options
      end


      def set_type_from_block(&block)
        @type = Class.new do
          include Embeddable
        end
        if block.arity == 1 # Traditional, with options
          @type.class_eval(&block)
        else
          @type.instance_eval(&block)
        end
      end

  end
end
