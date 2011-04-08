module CouchRest
  module Model
    module CoreExtensions
      module TimeParsing

        if RUBY_VERSION < "1.9.0"
          # Overrwrite Ruby's standard new method to provide compatible support
          # of 1.9.2's Time.new method.
          #
          # Only supports syntax like:
          #
          #   Time.new(2011, 4, 1, 18, 50, 32, "+02:00")
          #   # or
          #   Time.new(2011, 4, 1, 18, 50, 32)
          #
          def new(*args)
            return super() if (args.empty?)
            zone = args.delete_at(6)
            time = mktime(*args)
            if zone =~ /([\+|\-]?)(\d{2}):?(\d{2})/
              tz_difference = ("#{$1 == '-' ? '+' : '-'}#{$2}".to_i * 3600) + ($3.to_i * 60)
              time + tz_difference + zone_offset(time.zone)
            else
              time
            end
          end
        end

        # Attemtps to parse a time string in ISO8601 format.
        # If no match is found, the standard time parse will be used.
        #
        # Times, unless provided with a time zone, are assumed to be in 
        # UTC.
        #
        def parse_iso8601(string)
          if (string =~ /(\d{4})[\-|\/](\d{2})[\-|\/](\d{2})[T|\s](\d{2}):(\d{2}):(\d{2})(Z| ?([\+|\s|\-])?(\d{2}):?(\d{2}))?/)
            # $1 = year
            # $2 = month
            # $3 = day
            # $4 = hours
            # $5 = minutes
            # $6 = seconds
            # $7 = UTC or Timezone
            # $8 = time zone direction
            # $9 = tz difference hours
            # $10 = tz difference minutes

            if (!$7.to_s.empty? && $7 != 'Z')
              new($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i, "#{$8 == '-' ? '-' : '+'}#{$9}:#{$10}")
            else
              utc($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i)
            end
          else
            parse(string)
          end
        end

      end
    end
  end
end

Time.class_eval do
  extend CouchRest::Model::CoreExtensions::TimeParsing
end

