module CouchRest
  module Model
    class Base < CouchRest::Document

      extend ActiveModel::Naming

      include CouchRest::Model::Configuration
      include CouchRest::Model::Connection
      include CouchRest::Model::Persistence
      include CouchRest::Model::DocumentQueries
      include CouchRest::Model::Views
      include CouchRest::Model::DesignDoc
      include CouchRest::Model::ExtendedAttachments
      include CouchRest::Model::ClassProxy
      include CouchRest::Model::Proxyable
      include CouchRest::Model::Collection
      include CouchRest::Model::PropertyProtection
      include CouchRest::Model::Associations
      include CouchRest::Model::Validations
      include CouchRest::Model::Callbacks
      include CouchRest::Model::Designs
      include CouchRest::Model::CastedBy
      include CouchRest::Model::Dirty
      include CouchRest::Model::Callbacks

      def self.subclasses
        @subclasses ||= []
      end

      def self.inherited(subklass)
        super
        subklass.send(:include, CouchRest::Model::Properties)

        subklass.class_eval <<-EOS, __FILE__, __LINE__ + 1
          def self.inherited(subklass)
            super
            subklass.properties = self.properties.dup
            # This is nasty:
            subklass._validators = self._validators.dup
          end
        EOS
        subclasses << subklass
      end

      # Instantiate a new CouchRest::Model::Base by preparing all properties
      # using the provided document hash.
      #
      # Options supported:
      #
      # * :directly_set_attributes, true when data comes directly from database
      # * :database, provide an alternative database
      #
      # If a block is provided the new model will be passed into the
      # block so that it can be populated.
      def initialize(attributes = {}, options = {})
        super()
        prepare_all_attributes(attributes, options)
        # set the instance's database, if provided
        self.database = options[:database] unless options[:database].nil?
        unless self['_id'] && self['_rev']
          self[self.model_type_key] = self.class.to_s
        end

        yield self if block_given?

        after_initialize if respond_to?(:after_initialize)
        run_callbacks(:initialize) { self }
      end


      # Temp solution to make the view_by methods available
      def self.method_missing(m, *args, &block)
        if has_view?(m)
          query = args.shift || {}
          return view(m, query, *args, &block)
        elsif m.to_s =~ /^find_(by_.+)/
          view_name = $1
          if has_view?(view_name)
            return first_from_view(view_name, *args)
          end
        end
        super
      end

      # compatbility for 1.8, it does not use respond_to_missing?
      # thing is, when using it like this only, doing method(:find_by_view)
      # will throw an error
      def self.respond_to?(m, include_private = false)
        super || respond_to_missing?(m, include_private)
      end

      # ruby 1.9 feature
      # this allows ruby to know that the method is defined using
      # method_missing, and as such, method(:find_by_view) will actually
      # give a Method back, and not throw an error like in 1.8!
      def self.respond_to_missing?(m, include_private = false)
        has_view?(m) || has_view?(m.to_s[/^find_(by_.+)/, 1])
      end

      def to_key
        new? ? nil : [id]
      end

      alias :to_param :id
      alias :new_record? :new?
      alias :new_document? :new?

      # Compare this model with another by confirming to see 
      # if the IDs and their databases match!
      #
      # Camparison of the database is required in case the 
      # model has been proxied or loaded elsewhere.
      #
      # A Basic CouchRest document will only ever compare using 
      # a Hash comparison on the attributes.
      def == other
        return false unless other.is_a?(Base)
        if id.nil? && other.id.nil?
          # no ids? assume comparing nested and revert to hash comparison
          to_hash == other.to_hash
        else
          database == other.database && id == other.id
        end
      end
      alias :eql? :==

    end
  end
end
