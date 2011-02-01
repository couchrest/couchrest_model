# encoding: utf-8

module CouchRest #:nodoc:
  module Model #:nodoc:

    module Callbacks
      extend ActiveSupport::Concern
      included do
        extend ActiveModel::Callbacks

        define_model_callbacks \
          :create,
          :destroy,
          :save,
          :update

      end

      def valid?(*) #nodoc
        _run_validation_callbacks { super }
      end

    end

  end
end
