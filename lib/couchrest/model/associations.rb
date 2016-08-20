module CouchRest
  module Model
    # Basic support for relationships between CouchRest::Model::Base
    module Associations
      extend ActiveSupport::Concern

      module ClassMethods

        # Define an association that this object belongs to.
        #
        # An attribute will be created matching the name of the attribute
        # with '_id' on the end, or the foreign key (:foreign_key) provided.
        #
        # Searching for the assocated object is performed using a string 
        # (:proxy) to be evaulated in the context of the owner. Typically
        # this will be set to the class name (:class_name), or determined
        # automatically if the owner belongs to a proxy object.
        #
        # If the association owner is proxied by another model, than an attempt will
        # be made to automatically determine the correct place to request
        # the documents. Typically, this is a method with the pluralized name of the 
        # association inside owner's owner, or proxy.
        #
        # For example, imagine a company acts as a proxy for invoices and clients.
        # If an invoice belongs to a client, the invoice will need to access the
        # list of clients via the proxy. So a request to search for the associated
        # client from an invoice would look like:
        #
        #    self.company.clients
        #
        # If the name of the collection proxy is not the pluralized assocation name, 
        # it can be set with the :proxy_name option.
        #
        def belongs_to(attrib, *options)
          opts = merge_belongs_to_association_options(attrib, options.first)

          property(opts[:foreign_key], String, opts)

          create_association_property_setter(attrib, opts)
          create_belongs_to_getter(attrib, opts)
          create_belongs_to_setter(attrib, opts)
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
          opts = merge_belongs_to_association_options(attrib, options.first)
          opts[:foreign_key] = opts[:foreign_key].pluralize
          opts[:readonly] = true

          property(opts[:foreign_key], [String], opts)

          create_association_property_setter(attrib, opts)
          create_collection_of_getter(attrib, opts)
          create_collection_of_setter(attrib, opts)
        end


        private

        def merge_belongs_to_association_options(attrib, options = nil)
          opts = {
            :foreign_key => attrib.to_s.singularize + '_id',
            :class_name  => attrib.to_s.singularize.camelcase,
            :proxy_name  => attrib.to_s.pluralize,
            :allow_blank => false
          }
          opts.merge!(options) if options.is_a?(Hash)

          # Generate a string for the proxy method call
          # Assumes that the proxy_owner_method from "proxyable" is available.
          if opts[:proxy].to_s.empty?
            opts[:proxy] = if proxy_owner_method
              "self.#{proxy_owner_method}.#{opts[:proxy_name]}"
            else
              opts[:class_name]
            end
          end

          opts
        end

        ### Generic support methods

        def create_association_property_setter(attrib, options)
          # ensure CollectionOfProxy is nil, ready to be reloaded on request
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{options[:foreign_key]}=(value)
              @#{attrib} = nil
              write_attribute("#{options[:foreign_key]}", value)
            end
          EOS
        end

        ### belongs_to support methods

        def create_belongs_to_getter(attrib, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}
              @#{attrib} ||= #{options[:foreign_key]}.nil? ? nil : #{options[:proxy]}.get(self.#{options[:foreign_key]})
            end
          EOS
        end

        def create_belongs_to_setter(attrib, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}=(value)
              self.#{options[:foreign_key]} = value.nil? ? nil : value.id
              @#{attrib} = value
            end
          EOS
        end

        ### collection_of support methods

        def create_collection_of_getter(attrib, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}(reload = false)
              return @#{attrib} unless @#{attrib}.nil? or reload
              ary = self.#{options[:foreign_key]}.collect{|i| #{options[:proxy]}.get(i)}
              @#{attrib} = ::CouchRest::Model::CollectionOfProxy.new(ary, find_property('#{options[:foreign_key]}'), self)
            end
          EOS
        end

        def create_collection_of_setter(attrib, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}=(value)
              @#{attrib} = ::CouchRest::Model::CollectionOfProxy.new(value, find_property('#{options[:foreign_key]}'), self)
            end
          EOS
        end

      end

    end

    # Special proxy for a collection of items so that adding and removing
    # to the list automatically updates the associated property.
    class CollectionOfProxy < CastedArray

      def initialize(array, property, parent)
        (array ||= []).compact!
        super(array, property, parent)
        self.casted_by_attribute = [] # replace the original array!
        array.compact.each do |obj|
          check_obj(obj)
          casted_by_attribute << obj.id
        end
      end

      def << obj
        check_obj(obj)
        casted_by_attribute << obj.id
        super(obj)
      end

      def push(obj)
        check_obj(obj)
        casted_by_attribute.push obj.id
        super(obj)
      end

      def unshift(obj)
        check_obj(obj)
        casted_by_attribute.unshift obj.id
        super(obj)
      end

      def []= index, obj
        check_obj(obj)
        casted_by_attribute[index] = obj.id
        super(index, obj)
      end

      def pop
        casted_by_attribute.pop
        super
      end

      def shift
        casted_by_attribute.shift
        super
      end

      protected

      def casted_by_attribute=(value)
        casted_by.write_attribute(casted_by_property, value)
      end

      def casted_by_attribute
        casted_by.read_attribute(casted_by_property)
      end

      def check_obj(obj)
        raise "Object cannot be added to #{casted_by.class.to_s}##{casted_by_property.to_s} collection unless saved" if obj.new?
      end

      # Override CastedArray instantiation_and_cast method for a simpler
      # version that will not try to cast the model.
      def instantiate_and_cast(obj)
        obj.casted_by = casted_by if obj.respond_to?(:casted_by)
        obj.casted_by_property = casted_by_property if obj.respond_to?(:casted_by_property)
        obj
      end

    end

  end

end
