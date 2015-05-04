module CouchRest
  module Model
    module Designs

      # Support class that allows for a model's design
      # definition to be converted into an actual design document.
      #
      # The methods called in a DesignMapper instance will relay
      # the parameters to the appropriate method in the design document.
      #
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

        # Define a new view re-usable lib for shared functions.
        def view_lib(name, function)
          design_doc.create_view_lib(name, function)
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
