module CouchRest
  module Model
    module Associations

      # Basic support for relationships between CouchRest::Model::Base
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        # Define an association that this object belongs to.
        # 
        def belongs_to(attrib, *options)
          opts = {
            :foreign_key => attrib.to_s + '_id',
            :class_name => attrib.to_s.camelcase,
            :proxy => nil
          }
          case options.first
          when Hash
            opts.merge!(options.first)
          end

          begin
            opts[:class] = opts[:class_name].constantize
          rescue NameError
            raise NameError, "Unable to convert class name into Constant for #{self.name}##{attrib}"
          end

          prop = property(opts[:foreign_key], opts)

          create_belongs_to_getter(attrib, prop, opts)
          create_belongs_to_setter(attrib, prop, opts)

          prop
        end

        # Provide access to a collection of objects where the associated
        # property contains a list of the collection item ids.
        #
        # The following:
        #
        #     collection_of :groups
        #
        # creates a pseudo property called "groups" which allows access
        # to a CollectionOfProxy object. Adding, replacing or removing entries in this
        # proxy will cause the matching property array, in this case "group_ids", to
        # be kept in sync.
        #
        # Any manual changes made to the collection ids property (group_ids), unless replaced, will require
        # a reload of the CollectionOfProxy for the two sets of data to be in sync:
        #
        #     group_ids = ['123']
        #     groups == [Group.get('123')]
        #     group_ids << '321'
        #     groups == [Group.get('123')]
        #     groups(true) == [Group.get('123'), Group.get('321')]
        #
        # Of course, saving the parent record will store the collection ids as they are
        # found.
        #
        # The CollectionOfProxy supports the following array functions, anything else will cause
        # a mismatch between the collection objects and collection ids:
        #
        #     groups << obj
        #     groups.push obj
        #     groups.unshift obj
        #     groups[0] = obj
        #     groups.pop == obj
        #     groups.shift == obj
        #
        # Addtional options match those of the the belongs_to method.
        #
        # NOTE: This method is *not* recommended for large collections or collections that change
        # frequently! Use with prudence.
        #
        def collection_of(attrib, *options)
          opts = {
            :foreign_key => attrib.to_s.singularize + '_ids',
            :class_name => attrib.to_s.singularize.camelcase,
            :proxy => nil
          }
          case options.first
          when Hash
            opts.merge!(options.first)
          end
          begin
            opts[:class] = opts[:class_name].constantize
          rescue
            raise "Unable to convert class name into Constant for #{self.name}##{attrib}"
          end
          opts[:readonly] = true

          prop = property(opts[:foreign_key], [], opts)

          create_collection_of_property_setter(attrib, prop, opts)
          create_collection_of_getter(attrib, prop, opts)
          create_collection_of_setter(attrib, prop, opts)

          prop
        end


        private

        def create_belongs_to_getter(attrib, property, options)
          base = options[:proxy] || options[:class_name]
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}
              @#{attrib} ||= #{options[:foreign_key]}.nil? ? nil : (model_proxy || #{base}).get(self.#{options[:foreign_key]})
            end
          EOS
        end

        def create_belongs_to_setter(attrib, property, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}=(value)
              self.#{options[:foreign_key]} = value.nil? ? nil : value.id
              @#{attrib} = value
            end
          EOS
        end

        ### collection_of support methods

        def create_collection_of_property_setter(attrib, property, options)
          # ensure CollectionOfProxy is nil, ready to be reloaded on request
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{options[:foreign_key]}=(value)
              @#{attrib} = nil
              write_attribute("#{options[:foreign_key]}", value)
            end
          EOS
        end

        def create_collection_of_getter(attrib, property, options)
          base = options[:proxy] || options[:class_name]
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}(reload = false)
              return @#{attrib} unless @#{attrib}.nil? or reload
              ary = self.#{options[:foreign_key]}.collect{|i| (model_proxy || #{base}).get(i)}
              @#{attrib} = ::CouchRest::CollectionOfProxy.new(ary, self, '#{options[:foreign_key]}')
            end
          EOS
        end

        def create_collection_of_setter(attrib, property, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}=(value)
              @#{attrib} = ::CouchRest::CollectionOfProxy.new(value, self, '#{options[:foreign_key]}')
            end
          EOS
        end

      end

    end
  end

  # Special proxy for a collection of items so that adding and removing
  # to the list automatically updates the associated property.
  class CollectionOfProxy < Array
    attr_accessor :property
    attr_accessor :casted_by

    def initialize(array, casted_by, property)
      self.property = property
      self.casted_by = casted_by
      (array ||= []).compact!
      casted_by[property.to_s] = [] # replace the original array!
      array.compact.each do |obj|
        check_obj(obj)
        casted_by[property.to_s] << obj.id
      end
      super(array)
    end
    
    def << obj
      check_obj(obj)
      casted_by[property.to_s] << obj.id
      super(obj)
    end
    
    def push(obj)
      check_obj(obj)
      casted_by[property.to_s].push obj.id
      super(obj)
    end
    
    def unshift(obj)
      check_obj(obj)
      casted_by[property.to_s].unshift obj.id
      super(obj)
    end

    def []= index, obj
      check_obj(obj)
      casted_by[property.to_s][index] = obj.id
      super(index, obj)
    end

    def pop
      casted_by[property.to_s].pop
      super
    end
    
    def shift
      casted_by[property.to_s].shift
      super
    end

    protected

    def check_obj(obj)
      raise "Object cannot be added to #{casted_by.class.to_s}##{property.to_s} collection unless saved" if obj.new?
    end

  end


end
