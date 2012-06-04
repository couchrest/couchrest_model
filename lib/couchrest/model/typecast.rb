module CouchRest
  module Model
    module Typecast

      def typecast_value(value, property) # klass, init_method)
        return nil if value.nil?
        klass = property.type_class
        if value.instance_of?(klass) || klass == Object
          if klass == Time && !value.utc?
            value.utc # Ensure Time is always in UTC
          else
            value
          end
        elsif [String, TrueClass, Integer, Float, BigDecimal, DateTime, Time, Date, Class].include?(klass)
          send('typecast_to_'+klass.to_s.downcase, value)
        else
          property.build(value)
        end
      end

      protected

        # Typecast a value to an Integer
        def typecast_to_integer(value)
          typecast_to_numeric(value, :to_i)
        end

        # Typecast a value to a String
        def typecast_to_string(value)
          value.to_s
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

        # Typecast a value to a BigDecimal
        def typecast_to_bigdecimal(value)
          if value.kind_of?(Integer)
            value.to_s.to_d
          else
            typecast_to_numeric(value, :to_d)
          end
        end

        # Typecast a value to a Float
        def typecast_to_float(value)
          typecast_to_numeric(value, :to_f)
        end

        # Match numeric string
        def typecast_to_numeric(value, method)
          if value.respond_to?(:to_str)
            if value.strip.gsub(/,/, '.').gsub(/\.(?!\d*\Z)/, '').to_str =~ /\A(-?(?:0|[1-9]\d*)(?:\.\d+)?|(?:\.\d+))\z/
              $1.send(method)
            else
              value
            end
          elsif value.respond_to?(method)
            value.send(method)
          else
            value
          end
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
          if value.is_a?(Hash)
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

