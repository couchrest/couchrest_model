module CouchRest
  module Model
    module Typecast

      def typecast_value(parent, property, value)
        return nil if value.nil?
        type = property.type
        if value.instance_of?(type) || type == Object
          if type == Time && !value.utc?
            value.utc # Ensure Time is always in UTC
          else
            value
          end
        elsif type.respond_to?(:couchrest_typecast)
          type.couchrest_typecast(parent, property, value)
        elsif [String, Symbol, TrueClass, Integer, Float, BigDecimal, DateTime, Time, Date, Class].include?(type)
          send('typecast_to_'+type.to_s.downcase, value)
        else
          property.build(value)
        end
      end

      protected

        # Typecast a value to an Integer
        def typecast_to_integer(value)
          typecast_to_numeric(value, :to_i)
        end

        # Typecast a value to a BigDecimal
        def typecast_to_bigdecimal(value)
          typecast_to_numeric(value, :to_d)
        end

        # Typecast a value to a Float
        def typecast_to_float(value)
          typecast_to_numeric(value, :to_f)
        end

        # Convert some kind of object to a number that of the type
        # provided.
        #
        # When a string is provided, It'll attempt to filter out
        # region specific details such as commas instead of points
        # for decimal places, text units, and anything else that is
        # not a number and a human could make out.
        #
        # Esentially, the aim is to provide some kind of sanitary
        # conversion from values in incoming http forms.
        #
        # If what we get makes no sense at all, nil it.
        def typecast_to_numeric(value, method)
          if value.is_a?(String)
            value = value.strip.gsub(/,/, '.').gsub(/[^\d\-\.]/, '').gsub(/\.(?!\d*\Z)/, '')
            value.empty? ? nil : value.send(method)
          elsif value.respond_to?(method)
            value.send(method)
          else
            nil
          end
        end

        # Typecast a value to a String
        def typecast_to_string(value)
          value.to_s
        end

        def typecast_to_symbol(value)
          value.to_sym
        end

        # Typecast a value to a true or false
        def typecast_to_trueclass(value)
          if value.kind_of?(Integer)
            return true  if value == 1
            return false if value == 0
          elsif value.respond_to?(:to_s)
            return true  if %w[ true  1 t ].include?(value.to_s.downcase)
            return false if %w[ false 0 f ].include?(value.to_s.downcase)
          end
          value
        end

        # Typecasts an arbitrary value to a DateTime.
        # Handles both Hashes and DateTime instances.
        # This is slow!! Use Time instead.
        def typecast_to_datetime(value)
          if value.is_a?(Hash)
            typecast_hash_to_datetime(value)
          else
            DateTime.parse(value.to_s)
          end
        rescue ArgumentError
          value
        end

        # Typecasts an arbitrary value to a Date
        # Handles both Hashes and Date instances.
        def typecast_to_date(value)
          if value.is_a?(Hash)
            typecast_hash_to_date(value)
          elsif value.is_a?(Time) # sometimes people think date is time!
            value.to_date
          elsif value.to_s =~ /(\d{4})[\-|\/](\d{2})[\-|\/](\d{2})/
            # Faster than parsing the date
            Date.new($1.to_i, $2.to_i, $3.to_i)
          else
            Date.parse(value)
          end
        rescue ArgumentError
          value
        end

        # Typecasts an arbitrary value to a Time
        # Handles both Hashes and Time instances.
        def typecast_to_time(value)
          case value
          when Float # JSON oj already parses Time, FTW.
            Time.at(value).utc
          when Hash
            typecast_hash_to_time(value)
          else
            Time.parse_iso8601(value.to_s)
          end
        rescue ArgumentError
          value
        rescue TypeError
          value
        end

        # Creates a DateTime instance from a Hash with keys :year, :month, :day,
        # :hour, :min, :sec
        def typecast_hash_to_datetime(value)
          DateTime.new(*extract_time(value))
        end

        # Creates a Date instance from a Hash with keys :year, :month, :day
        def typecast_hash_to_date(value)
          Date.new(*extract_time(value)[0, 3].map(&:to_i))
        end

        # Creates a Time instance from a Hash with keys :year, :month, :day,
        # :hour, :min, :sec
        def typecast_hash_to_time(value)
          Time.utc(*extract_time(value))
        end

        # Extracts the given args from the hash. If a value does not exist, it
        # uses the value of Time.now.
        def extract_time(value)
          now = Time.now
          [:year, :month, :day, :hour, :min, :sec].map do |segment|
            typecast_to_numeric(value.fetch(segment, now.send(segment)), :to_i)
          end
        end

        # Typecast a value to a Class
        def typecast_to_class(value)
          value.to_s.constantize
        rescue NameError
          value
        end

    end
  end
end

