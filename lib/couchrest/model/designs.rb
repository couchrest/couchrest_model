
#### NOTE Work in progress! Not yet used!

module CouchRest
  module Model

    # A design block in CouchRest Model groups together the functionality of CouchDB's
    # design documents in a simple block definition.
    #
    #   class Person < CouchRest::Model::Base
    #     property :name
    #     timestamps!
    #
    #     design do
    #       view :by_name
    #     end
    #   end
    #
    module Designs
      extend ActiveSupport::Concern


      module ClassMethods

        # Add views and other design document features
        # to the current model.
        def design(prefix = nil, &block)

          # Store ourselves a copy of this design spec incase any other model inherits.
          (@_design_blocks ||= [ ]) << {:args => [prefix], :block => block}

          mapper = DesignMapper.new(self, prefix)
          mapper.instance_eval(&block) if block_given?

          # Create an 'all' view if no prefix and one has not been defined already
          mapper.view(:all) if prefix.nil? and !mapper.design_doc.has_view?(:all)
        end

        def inherited(model)
          super

          # Go through our design blocks and re-implement them in the child.
          unless @_design_blocks.nil?
            @_design_blocks.each do |row|
              model.design(*row[:args], &row[:block])
            end
          end
        end

        # Override the default page pagination value:
        #
        #   class Person < CouchRest::Model::Base
        #     paginates_per 10
        #   end
        #
        def paginates_per(val)
          @_default_per_page = val
        end

        # The models number of documents to return
        # by default when performing pagination.
        # Returns 25 unless explicitly overridden via <tt>paginates_per</tt>
        def default_per_page
          @_default_per_page || 25
        end

        def design_docs
          @_design_docs ||= []
        end

      end

      # Map method calls defined in a design block to actions
      # in the Design Document.
      class DesignMapper

        # Basic mapper attributes
        attr_accessor :model, :method, :prefix

        # Temporary variable storing the design doc
        attr_accessor :design_doc

        def initialize(model, prefix = nil)
          self.model  = model
          self.prefix = prefix
          self.method = Design.method_name(prefix)

          create_model_design_doc_reader
          self.design_doc = model.send(method) || assign_model_design_doc
        end

        def disable_auto_update
          design_doc.auto_update = false
        end

        def enable_auto_update
          design_doc.auto_update = true
        end

        # Add the specified view to the design doc the definition was made in
        # and create quick access methods in the model.
        def view(name, opts = {})
          design_doc.create_view(name, opts)
        end

        # Really simple design function that allows a filter
        # to be added. Filters are simple functions used when listening
        # to the _changes feed.
        #
        # No methods are created here, the design is simply updated.
        # See the CouchDB API for more information on how to use this.
        def filter(name, function)
          design_doc.create_filter(name, function)
        end

        # Convenience wrapper to access model's type key option.
        def model_type_key
          model.model_type_key
        end

        protected

        # Create accessor in model and assign a new design doc.
        # New design doc is returned ready to use.
        def create_model_design_doc_reader
          model.instance_eval "def #{method}; @#{method}; end"
        end

        def assign_model_design_doc
          doc = Design.new(model, prefix)
          model.instance_variable_set("@#{method}", doc)
          model.design_docs << doc

          # Set defaults
          doc.auto_update = model.auto_update_design_doc

          doc
        end

      end
    end
  end
end
