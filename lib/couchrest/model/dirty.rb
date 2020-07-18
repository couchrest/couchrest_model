module CouchRest
  module Model

    # This applies to both Model::Base and Model::CastedModel
    module Dirty
      extend ActiveSupport::Concern

      included do
        # The original attributes data hash, used for comparing changes.
        self.send(:attr_reader, :original_change_data)
      end

      def use_dirty?
        # Use the configuration option.
        !disable_dirty_tracking
      end

      # Provide an array of changes according to the hashdiff gem of the raw
      # json hash data.
      # If dirty tracking is disabled, this will always return nil.
      def changes
        if original_change_data.nil?
          nil
        else
          Hashdiff.diff(original_change_data, current_change_data)
        end
      end

      # Has this model changed? If dirty tracking is disabled, this method
      # will always return true.
      def changed?
        diff = changes
        diff.nil? || !diff.empty?
      end

      def clear_changes_information
        if use_dirty?
          # Recursively clear all change information
          self.class.properties.each do |property|
            val = read_attribute(property)
            if val.respond_to?(:clear_changes_information)
              val.clear_changes_information
            end
          end
          @original_change_data = current_change_data
        else
          @original_change_data = nil
        end
      end

      protected

      def current_change_data
        as_couch_json.as_json
      end

      module ClassMethods

        def create_dirty_property_methods(property)
          create_dirty_property_change_method(property)
          create_dirty_property_changed_method(property)
          create_dirty_property_was_method(property)
        end

        # For #property_change.
        # Tries to be a bit more efficient by directly comparing the properties
        # current value with that stored in the original change data. This also
        # maintains compatibility with ActiveModel change results.
        def create_dirty_property_change_method(property)
          define_method("#{property.name}_change") do
            val = read_attribute(property.name)
            if val.respond_to?(:changes)
              val.changes
            else
              if original_change_data.nil?
                nil
              else
                orig = original_change_data[property.name]
                cur = val.as_json
                if orig != cur
                  [orig, cur]
                else
                  []
                end
              end
            end
          end
        end

        # For #property_was value.
        # Uses the original raw value, if available.
        def create_dirty_property_was_method(property)
          define_method("#{property.name}_was") do
            if original_change_data.nil?
              nil
            else
              original_change_data[property.name]
            end
          end
        end

        # For #property_changed?
        def create_dirty_property_changed_method(property)
          define_method("#{property.name}_changed?") do
            changes = send("#{property.name}_change")
            changes.nil? || !changes.empty?
          end
        end

      end
    end
  end
end
