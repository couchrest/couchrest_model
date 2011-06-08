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

      def valid?(context = nil)
        context ||= (new_record? ? :create : :update)
        output = super(context)
        errors.empty? && output
      end

    end

  end
end
