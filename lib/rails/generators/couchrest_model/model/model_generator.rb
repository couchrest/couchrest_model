require 'rails/generators/couchrest_model'

module CouchrestModel
  module Generators
    class ModelGenerator < Base
      check_class_collision

      def create_model_file
        template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end

      def create_module_file
        return if class_path.empty?
        template 'module.rb', File.join('app/models', "#{class_path.join('/')}.rb") if behavior == :invoke
      end
      
      hook_for :test_framework

      protected

        def parent_class_name
          "CouchRest::Model::Base"
        end

    end
  end
end
