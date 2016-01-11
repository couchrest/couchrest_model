# encoding: utf-8
module CouchRest
  module Model
    module Errors

      class CouchRestModelError < StandardError; end

      # Raised when a persisence method ending in ! fails validation. The message
      # will contain the full error messages from the +Document+ in question.
      #
      # Example:
      #
      # <tt>Validations.new(person.errors)</tt>
      class Validations < CouchRestModelError
        attr_reader :document
        def initialize(document)
          @document = document
          super("Validation Failed: #{@document.errors.full_messages.join(", ")}")
        end
      end
    end

    class DocumentNotFound < Errors::CouchRestModelError; end

    class DatabaseNotDefined < Errors::CouchRestModelError
      def initialize(msg = nil)
        msg ||= "Database must be defined in model or view!"
        super(msg)
      end
    end

  end
end
