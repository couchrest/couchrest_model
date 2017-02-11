module CouchRest
  module Model
  
    # Thead safe caching of connection configuration files.
    class ConnectionConfig
      include Singleton

      def initialize
        @config_files = {}
        @mutex = Mutex.new
      end

      def [](file)
        @mutex.synchronize do
          @config_files[file] ||= load_config(file)
        end
      end

      private

      def load_config(file)
        if File.exists?(file)
          YAML::load(ERB.new(IO.read(file)).result).symbolize_keys
        else
          { }
        end
      end

    end

  end
end
