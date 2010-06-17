module CouchRest
  module Mixins
    module Associations

      # Basic support for relationships between ExtendedDocuments
      
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def belongs_to(attrib, *options)
          opts = {
            :foreign_key => attrib.to_s + '_id',
            :class_name => attrib.to_s.camelcase
          }
          case options.first
          when Hash
            opts.merge!(options.first)
          end

          begin
            opts[:class] = opts[:class_name].constantize
          rescue
            raise "Unable to convert belongs_to class name into Constant for #{self.name}##{attrib}"
          end

          prop = property(opts[:foreign_key])

          create_belongs_to_getter(attrib, prop, opts)
          create_belongs_to_setter(attrib, prop, opts)

          prop
        end

        def create_belongs_to_getter(attrib, property, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}
              @#{attrib} ||= #{options[:class_name]}.get(self.#{options[:foreign_key]})
            end
          EOS
        end

        def create_belongs_to_setter(attrib, property, options)
          class_eval <<-EOS, __FILE__, __LINE__ + 1
            def #{attrib}=(value)
              @#{attrib} = value
              self.#{options[:foreign_key]} = value.nil? ? nil : value.id
            end
          EOS
        end

      end

    end
  end
end
