module CouchRest
  module Model
    module Connection
      extend ActiveSupport::Concern

      def server
        self.class.server
      end

      module ClassMethods

        # Overwrite the CouchRest::Document.use_database method so that a database
        # name can be provided instead of a full connection.
        # We prepare the database immediatly, so ensure any connection details
        # are provided in advance.
        # Note that this will not work correctly with proxied models.
        def use_database(db)
          @database = prepare_database(db)
        end

        # Overwrite the default database method so that it always
        # provides something from the configuration.
        # It will try to inherit the database from an ancester
        # unless the use_database method has been used.
        def database
          @database ||= prepare_database(super)
        end

        def server
          @server ||= ServerPool.instance[prepare_server_uri]
        end

        def prepare_database(db = nil)
          if db.nil? || db.is_a?(String) || db.is_a?(Symbol)
            self.server.database!(prepare_database_name(db))
          else
            db
          end
        end

        protected

        def prepare_database_name(base)
          conf = connection_configuration
          [conf[:prefix], base.to_s, conf[:suffix]].reject{|s| s.to_s.empty?}.join(conf[:join])
        end

        def prepare_server_uri
          conf = connection_configuration
          userinfo = [conf[:username], conf[:password]].compact.join(':')
          userinfo += '@' unless userinfo.empty?
          "#{conf[:protocol]}://#{userinfo}#{conf[:host]}:#{conf[:port]}"
        end

        def connection_configuration
          @connection_configuration ||=
            self.connection.merge(
              (load_connection_config_file[environment.to_sym] || {}).symbolize_keys
            )
        end

        def load_connection_config_file
          file = connection_config_file
          ConnectionConfig.instance[file]
        end

      end

    end
  end
end
