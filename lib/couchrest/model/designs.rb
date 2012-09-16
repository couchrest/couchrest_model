
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

        # Define a Design Document associated with the current model.
        #
        # This class method supports several cool features that make it much
        # easier to define design documents.
        #
        # Adding a prefix allows you to associate multiple design documents with the same
        # model. This is useful if you'd like to split your designs into seperate
        # use cases; one for regular search functions and a second for stats for example.
        # 
        #    # Create a design doc with id _design/Cats
        #    design do
        #      view :by_name
        #    end
        #
        #    # Create a design doc with id _design/Cats_stats
        #    design :stats do
        #      view :by_age, :reduce => :stats
        #    end
        #
        #
        def design(*args, &block)
          opts = prepare_design_options(*args)

          # Store ourselves a copy of this design spec incase any other model inherits.
          (@_design_blocks ||= [ ]) << {:args => args, :block => block}

          mapper = DesignMapper.new(self, opts[:prefix])
          mapper.instance_eval(&block) if block_given?

          # Create an 'all' view if no prefix and one has not been defined already
          mapper.view(:all) if opts[:prefix].nil? and !mapper.design_doc.has_view?(:all)
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

        private

        def prepare_design_options(*args)
          options = {}
          if !args.first.is_a?(Hash)
            options[:prefix] = args.shift
          end
          options.merge(args.last) unless args.empty?
          prepare_source_paths(options)
          options
        end

        def prepare_source_paths(options)
          
        end

      end

    end
  end
end
