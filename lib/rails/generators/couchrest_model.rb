require 'rails/generators/named_base'
require 'rails/generators/active_model'
require 'couchrest_model'

module CouchrestModel
  module Generators
    class Base < Rails::Generators::NamedBase #:nodoc:
      
      # Set the current directory as base for the inherited generators.
      def self.base_root
        File.dirname(__FILE__)
      end
      
    end
  end
end
