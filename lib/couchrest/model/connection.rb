module CouchRest
  module Model
    module Connection
      extend ActiveSupport::Concern

      def server
        self.class.server
      end

      module ClassMethods

        # Overwrite the normal use_database method so that a database
        # name can be provided instead of a full connection.
        def use_database(db)
          @database = prepare_database(db)
        end

        # Overwrite the default database method so that it always
        # provides something from the configuration
        def database
          super || (@database ||= prepare_database)
        end

        def server
          @server ||= CouchRest::Server.new(prepare_server_uri)
        end

        def prepare_database(db = nil)
          unless db.is_a?(CouchRest::Database)
            conf = connection_configuration
            db = [conf[:prefix], db.to_s, conf[:suffix]].reject{|s| s.to_s.empty?}.join(conf[:join])
            self.server.database!(db)
          else
            db
          end
        end

        protected

        def prepare_server_uri
          conf = connection_configuration
          userinfo = [conf[:username], conf[:password]].compact.join(':')
          userinfo += '@' unless userinfo.empty?
          "#{conf[:protocol]}://#{userinfo}#{conf[:host]}:#{conf[:port]}"
        end

        def connection_configuration
          @connection_configuration ||=
            self.connection.update(
              (load_connection_config_file[environment] || {}).symbolize_keys
            )
        end

        def load_connection_config_file
          connection_config_cache[connection_config_file] ||=
            (File.exists?(connection_config_file) ?
              YAML::load(ERB.new(IO.read(connection_config_file)).result) :
              { }).symbolize_keys
        end

        def connection_config_cache
          Thread.current[:connection_config_cache] ||= {}
        end
      end

    end
  end
end
