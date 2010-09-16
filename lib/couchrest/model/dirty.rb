# encoding: utf-8
require 'active_model/dirty'

module CouchRest #:nodoc:
  module Model #:nodoc:

    # Dirty Tracking support via ActiveModel
    # mixin methods include:
    #   #changed?, #changed, #changes, #previous_changes
    #   #<attribute>_changed?, #<attribute>_change,
    #   #reset_<attribute>!, #<attribute>_will_change!,
    #   and #<attribute>_was
    #
    # Please see the specs or the documentation of
    # ActiveModel::Dirty for more information
    module Dirty
      extend ActiveSupport::Concern

      included do
        include ActiveModel::Dirty
        after_save :clear_changed_attributes
      end

      def initialize(*args)
        super
        @changed_attributes.clear if @changed_attributes
      end

      def write_attribute(name, value)
        meth = :"#{name}_will_change!"
        __send__ meth if respond_to? meth
        super
      end

      private

      def clear_changed_attributes
        @previously_changed = changes
        @changed_attributes.clear
        true
      end
    end
  end
end
