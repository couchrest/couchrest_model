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
        # Uses String#to_r on seconds portion to avoid rounding errors. Eg:
        #     Time.parse_iso8601("2014-12-11T16:54:54.549Z").as_json
        #      => "2014-12-11T16:54:54.548Z"
        #
        # See: https://bugs.ruby-lang.org/issues/7829
        #

        def parse_iso8601(string)
          if (string =~ /(\d{4})[\-|\/](\d{2})[\-|\/](\d{2})[T|\s](\d{2}):(\d{2}):(\d{2}(\.\d+)?)(Z| ?([\+|\s|\-])?(\d{2}):?(\d{2}))?/)
            # $1 = year
            # $2 = month
            # $3 = day
            # $4 = hours
            # $5 = minutes
            # $6 = seconds (with $7 for fraction)
            # $8 = UTC or Timezone
            # $9 = time zone direction
            # $10 = tz difference hours
            # $11 = tz difference minutes

            if $8 == 'Z' || $8.to_s.empty?
              utc($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_r)
            else
              new($1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_r, "#{$9 == '-' ? '-' : '+'}#{$10}:#{$11}")
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

  # Override the ActiveSupport's Time#as_json method to ensure that we *always* encode
  # using the iso8601 format and include fractional digits (3 by default).
  #
  # Including miliseconds in Time is very important for CouchDB to ensure that order
  # is preserved between models created in the same second.
  #
  # The number of fraction digits can be set by providing it in the options:
  #
  #    time.as_json(:fraction_digits => 6)
  #
  # The CouchRest Model +time_fraction_digits+ configuration option is used for the
  # default fraction. Given the global nature of Time#as_json method, this configuration
  # option can only be set for the whole project.
  #
  #    CouchRest::Model::Base.time_fraction_digits = 6
  #

  def as_json(options = {})
    digits = options ? options[:fraction_digits] : nil
    fraction = digits || CouchRest::Model::Base.time_fraction_digits
    xmlschema(fraction)
  end

end

