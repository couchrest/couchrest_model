module CouchRest
  module Model

    # Simple Server Pool with thread safety so that a single server
    # instance can be shared with multiple classes.
    class ServerPool
      include Singleton

      def initialize
        @servers = {}
        @mutex = Mutex.new
      end

      def [](url)
        @mutex.synchronize do
          @servers[url] ||= CouchRest::Server.new(url)
        end
      end

    end
  end
end
