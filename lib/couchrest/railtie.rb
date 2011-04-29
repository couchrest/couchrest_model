require "rails"
require "active_model/railtie"

module CouchRest
  # = Active Record Railtie
  class ModelRailtie < Rails::Railtie
    config.generators.orm :couchrest_model
    config.generators.test_framework  :test_unit, :fixture => false

    initializer "couchrest_model.configure_default_connection" do
      CouchRest::Model::Base.configure do |conf|
        conf.environment = Rails.env
        conf.connection_config_file = File.join(Rails.root, 'config', 'couchdb.yml')
        conf.connection[:prefix] =
          Rails.application.class.to_s.underscore.gsub(/\/.*/, '')
      end
    end
  end

end

