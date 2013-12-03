module CouchRest
  module Model
    class Base < CouchRest::Document

      include ActiveModel::Conversion

      extend Translation

      include Configuration
      include Connection
      include Persistence
      include DocumentQueries
      include ExtendedAttachments
      include Proxyable
      include PropertyProtection
      include Associations
      include Validations
      include Callbacks
      include Designs
      include CastedBy
      include Dirty
      

      def self.subclasses
        @subclasses ||= []
      end

      def self.inherited(subklass)
        super
        subklass.send(:include, Properties)

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
          self[self.model_type_key] = self.class.model_type_value
        end

        yield self if block_given?

        after_initialize if respond_to?(:after_initialize)
        run_callbacks(:initialize) { self }
      end

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
