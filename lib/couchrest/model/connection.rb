module CouchRest
  module Model
    module Connection
      extend ActiveSupport::Concern

      def database
        self.class.database
      end

      def server
        self.class.server
      end

      module ClassMethods

        # Overwrite the normal use_database method so that a database
        # name can be provided instead of a full connection.
        def use_database(db)
          @_database_name = db
        end

        # Replace CouchRest's database reader with a more advanced
        # version that will make a best guess at the database you might
        # want to use. Allows for a string to be provided instead of 
        # a database object.
        def database
          @database ||= prepare_database(@_database_name)
        end

        def server
          @server ||= CouchRest::Server.new(prepare_server_uri)
        end

        def prepare_database(db = nil)
          unless db.is_a?(CouchRest::Database)
            conf = connection_configuration
            db = [conf[:prefix], db.to_s, conf[:suffix]].compact.join('_')
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
          @server_configuration ||=
            self.connection.update(
              (load_connection_config_file[environment] || {}).symbolize_keys
            )
        end

        def load_connection_config_file
          connection_config_cache[connection_config_file] ||=
            File.exists?(connection_config_file) ?
              YAML::load(ERB.new(IO.read(connection_config_file)).result) :
              { }
        end

        def connection_config_cache
          Thread.current[:connection_config_cache] ||= {}
        end
      end

    end
  end
end
