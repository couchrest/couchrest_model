module CouchRest

  # CouchRest Model Configuration support, stolen from Carrierwave by jnicklas
  #    http://github.com/jnicklas/carrierwave/blob/master/lib/carrierwave/uploader/configuration.rb

  module Model
    module Configuration
      extend ActiveSupport::Concern

      included do
        add_config :model_type_key
        add_config :mass_assign_any_attribute
        add_config :auto_update_design_doc
        add_config :environment
        add_config :connection
        add_config :connection_config_file

        configure do |config|
          config.model_type_key = 'model' # was 'couchrest-type'
          config.mass_assign_any_attribute = false
          config.auto_update_design_doc = true

          config.environment = defined?(Rails) ? Rails.env : :development

          config.connection_config_file =
            File.join(
              defined?(Rails) ? Rails.root : Dir.pwd,
              'config', 'couchdb.yml'
            )

          app_name = defined?(Rails) ? Rails.application.class.to_s.underscore.gsub(/\/.*/, '') : 'couchrest'
          config.connection = {
            :protocol => 'http',
            :host     => 'localhost',
            :port     => '5984',
            :prefix   => app_name,
            :suffix   => nil,
            :join     => '_',
            :username => nil,
            :password => nil
          }
        end
      end

      module ClassMethods

        def add_config(name)
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def self.#{name}(value=nil)
              @#{name} = value if value
              return @#{name} if self.object_id == #{self.object_id} || defined?(@#{name})
              name = superclass.#{name}
              return nil if name.nil? && !instance_variable_defined?("@#{name}")
              @#{name} = name && !name.is_a?(Module) && !name.is_a?(Symbol) && !name.is_a?(Numeric) && !name.is_a?(TrueClass) && !name.is_a?(FalseClass) ? name.dup : name
            end

            def self.#{name}=(value)
              @#{name} = value
            end

            def #{name}
              self.class.#{name}
            end
          RUBY
        end

        def configure
          yield self
        end
      end

    end
  end
end
