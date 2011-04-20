module CouchRest
  module Model
    class Base < Document

      extend ActiveModel::Naming

      include CouchRest::Model::Configuration
      include CouchRest::Model::Persistence
      include CouchRest::Model::Callbacks
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
      include CouchRest::Model::Designs
      include CouchRest::Model::Dirty
      include CouchRest::Model::CastedBy

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

      # Accessors
      attr_accessor :casted_by


      # Instantiate a new CouchRest::Model::Base by preparing all properties
      # using the provided document hash.
      #
      # Options supported:
      #
      # * :directly_set_attributes: true when data comes directly from database
      # * :database: provide an alternative database
      #
      def initialize(doc = {}, options = {})
        doc = prepare_all_attributes(doc, options)
        # set the instances database, if provided
        self.database = options[:database] unless options[:database].nil?
        super(doc)
        unless self['_id'] && self['_rev']
          self[self.model_type_key] = self.class.to_s
        end
        after_initialize if respond_to?(:after_initialize)
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

      ### instance methods

      # Checks if we're the top document
      # (overrides base_doc? in casted_by.rb)
      def base_doc?
        !@casted_by
      end

      ## Compatibility with ActiveSupport and older frameworks

      # Hack so that CouchRest::Document, which descends from Hash,
      # doesn't appear to Rails routing as a Hash of options
      def is_a?(klass)
        return false if klass == Hash
        super
      end
      alias :kind_of? :is_a?

      def persisted?
        !new?
      end

      def to_key
        new? ? nil : [id]
      end

      alias :to_param :id
      alias :new_record? :new?
      alias :new_document? :new?
    end
  end
end
