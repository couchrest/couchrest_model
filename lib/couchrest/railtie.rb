require "rails"
require "active_model/railtie"

module CouchRest
  class ModelRailtie < Rails::Railtie
    def self.generator
      config.respond_to?(:app_generators) ? :app_generators : :generators
    end

    config.send(generator).orm :couchrest_model
    config.send(generator).test_framework  :test_unit, :fixture => false

    initializer "couchrest_model.configure_default_connection" do
      CouchRest::Model::Base.configure do |conf|
        conf.environment = Rails.env
        conf.connection_config_file = File.join(Rails.root, 'config', 'couchdb.yml')
        conf.connection[:prefix] =
          Rails.application.class.to_s.underscore.gsub(/\/.*/, '')
      end
    end

    config.before_configuration do
      config.couchrest_model = CouchRest::Model::Base
    end

    rake_tasks do
      Dir[File.join(File.dirname(__FILE__),'../tasks/*.rake')].each { |f| load f }
    end
  end

end

