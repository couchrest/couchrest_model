require "rails"
require "active_model/railtie"

module CouchrestModel
  # = Active Record Railtie
  class Railtie < Rails::Railtie
    config.generators.orm :couchrest
    config.generators.test_framework  :test_unit, :fixture => false
  end
  
end
                                      