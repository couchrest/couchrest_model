require 'rails/generators/couchrest_model'

module CouchrestModel
  module Generators
    class ConfigGenerator < Rails::Generators::Base
      source_root File.expand_path('../templates', __FILE__)

      def app_name
        Rails::Application.subclasses.first.parent.to_s.underscore
      end

      def copy_configuration_file
        template 'couchdb.yml', File.join('config', "couchdb.yml")
      end

    end
  end
end