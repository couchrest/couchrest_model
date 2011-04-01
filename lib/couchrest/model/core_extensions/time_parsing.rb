module CouchRest
  module Model
    module CoreExtensions
      module TimeParsing

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

