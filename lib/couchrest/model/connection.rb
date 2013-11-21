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
        # The actual database will be validated when it is requested for use.
        def use_database(db)
          if db.is_a?(CouchRest::Database)
            @database = db
          else
            @_use_database = db
          end
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
          if db.nil? || !db.is_a?(CouchRest::Database)
            conf = connection_configuration
            db ||= @_use_database
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
              (load_connection_config_file[environment.to_sym] || {}).symbolize_keys
            )
        end

        def load_connection_config_file
          file = connection_config_file
          connection_config_cache[file] ||=
            (File.exists?(file) ?
              YAML::load(ERB.new(IO.read(file)).result) :
              { }).symbolize_keys
        end

        def connection_config_cache
          Thread.current[:connection_config_cache] ||= {}
        end

      end

    end
  end
end
