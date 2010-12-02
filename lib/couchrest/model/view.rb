
#### NOTE Work in progress! Not yet used!

module CouchRest
  module Model

    # A proxy class that allows view queries to be created using
    # chained method calls. After each call a new instance of the method
    # is created based on the original in a similar fashion to ruby's sequel 
    # library, or Rails 3's Arel.
    #
    # CouchDB views have inherent limitations, so joins and filters as used in 
    # a normal relational database are not possible. At least not yet!
    #
    # 
    #
    class View

      attr_accessor :query, :design, :database, :name

      # Initialize a new View object. This method should not be called from outside CouchRest Model.
      def initialize(parent, new_query = {}, name = nil)
        if parent.is_a? Base
          raise "Name must be provided for view to be initialized" if name.nil?
          @name = name
          @database = parent.database
          @query = { :reduce => false }
        elsif parent.is_a? View
          @database = parent.database
          @query = parent.query.dup
        else
          raise "View cannot be initialized without a parent Model or View"
        end
        @query.update(new_query)
        super
      end


      # == View Execution Methods
      #
      # Send a request to the CouchDB database using the current query values.

      # Inmediatly send a request to the database for all documents provided by the query.
      #
      def all(&block)
        args = include_docs.query
        
      end

      # Inmediatly send a request for the first result of the dataset. This will override 
      # any limit set in the view previously.
      def first(&block)
        args = limit(1).include_docs.query

      end

      def info

      end

      def offset

      end

      def total_rows

      end

      def rows

      end


      # == View Filter Methods
      # 
      # View filters return an copy of the view instance with the query 
      # modified appropriatly. Errors will be raised if the methods
      # are combined in an incorrect fashion.
      #
      

      # Find all entries in the index whose key matches the value provided.
      #
      # Cannot be used when the +#startkey+ or +#endkey+ have been set.
      def key(value)
        raise "View#key cannot be used when startkey or endkey have been set" unless query[:startkey].nil? && query[:endkey].nil?
        update_query(:key => value)
      end

      # Find all index keys that start with the value provided. May or may not be used in
      # conjunction with the +endkey+ option.
      #
      # When the +#descending+ option is used (not the default), the start and end keys should
      # be reversed.
      #
      # Cannot be used if the key has been set.
      def startkey(value)
        raise "View#startkey cannot be used when key has been set" unless query[:key].nil?
        update_query(:startkey => value)
      end

      # The result set should start from the position of the provided document. 
      # The value may be provided as an object that responds to the +#id+ call
      # or a string.
      def startkey_doc(value)
        update_query(:startkey_docid => value.is_a?(String) ? value : value.id
      end

      # The opposite of +#startkey+, finds all index entries whose key is before the value specified.
      #
      # See the +#startkey+ method for more details and the +#inclusive_end+ option.
      def endkey(value)
        raise "View#endkey cannot be used when key has been set" unless query[:key].nil?
        update_query(:endkey => value)
      end

      # The result set should end at the position of the provided document. 
      # The value may be provided as an object that responds to the +#id+ call
      # or a string.
      def endkey_doc(value)
        update_query(:endkey_docid => value.is_a?(String) ? value : value.id
      end


      # The results should be provided in descending order.
      #
      # Descending is false by default, this method will enable it and cannot be undone.
      def descending
        update_query(:descending => true)
      end

      # Limit the result set to the value supplied.
      def limit(value)
        update_query(:limit => value)
      end

      # Skip the number of entries in the index specified by value. This would be
      # the equivilent of an offset in SQL.
      #
      # The CouchDB documentation states that the skip option should not be used
      # with large data sets as it is inefficient. Use the +startkey_doc+ method
      # instead to skip ranges efficiently.
      def skip(value = 0)
        update_query(:skip => value)
      end

      # Use the reduce function on the view. If none is available this method will fail. 
      def reduce
        update_query(:reduce => true)
      end

      # Control whether the reduce function reduces to a set of distinct keys or to a single
      # result row.
      #
      # By default the value is false, and can only be set when the view's +#reduce+ option
      # has been set.
      def group
        raise "View#reduce must have been set before grouping is permitted" unless query[:reduce]
        update_query(:group => true)
      end

      def group_level(value)
        raise "View#reduce and View#group must have been set before group_level is called" unless query[:reduce] && query[:group]
        update_query(:group_level => value.to_i)
      end


      protected

      def update_query(new_query = {})
        self.class.new(self, new_query)
      end

      # Used internally to ensure that docs are provided. Should not be used outside of 
      # the view class under normal circumstances.
      def include_docs
        raise "Documents cannot be returned from a view that is prepared for a reduce" if query[:reduce]
        update_query(:include_docs => true)
      end
      
      
      def execute(&block)


      end


    end
  end
end
