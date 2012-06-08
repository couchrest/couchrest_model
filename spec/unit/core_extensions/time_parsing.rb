# encoding: utf-8
require File.expand_path('../../../spec_helper', __FILE__)

describe "Time Parsing core extension" do

  describe "Time" do

    it "should respond to .parse_iso8601" do
      Time.respond_to?("parse_iso8601").should be_true
    end

    describe "#as_json" do

      it "should convert local time to JSON string" do
        time = Time.new(2011, 04, 01, 19, 05, 30, "+02:00")
        time.as_json.should eql("2011-04-01T19:05:30.000+02:00")
      end

      it "should convert utc time to JSON string" do
        time = Time.utc(2011, 04, 01, 19, 05, 30)
        time.as_json.should eql("2011-04-01T19:05:30.000Z")
      end

      it "should convert local time with fraction to JSON" do
        time = Time.new(2011, 04, 01, 19, 05, 30.123, "+02:00")
        time.as_json.should eql("2011-04-01T19:05:30.123+02:00")
      end

      it "should convert utc time with fraction to JSON" do
        time = Time.utc(2011, 04, 01, 19, 05, 30.123)
        time.as_json.should eql("2011-04-01T19:05:30.123Z")
      end

      it "should allow fraction digits" do
        time = Time.utc(2011, 04, 01, 19, 05, 30.123456)
        time.as_json(:fraction_digits => 6).should eql("2011-04-01T19:05:30.123456Z")
      end

      it "should use CouchRest::Model::Base.time_fraction_digits config option" do
        CouchRest::Model::Base.time_fraction_digits = 6
        time = Time.utc(2011, 04, 01, 19, 05, 30.123456)
        time.as_json.should eql("2011-04-01T19:05:30.123456Z")
        CouchRest::Model::Base.time_fraction_digits = 3 # Back to normal
      end

      it "should cope with a nil options parameter" do
        time = Time.utc(2011, 04, 01, 19, 05, 30.123456)
        lambda { time.as_json(nil) }.should_not raise_error
      end

    end

    describe ".parse_iso8601" do

      describe "parsing" do

        before :each do
          # Time.parse should not be called for these tests!
          Time.stub!(:parse).and_return(nil)
        end

        it "should parse JSON time" do
          txt = "2011-04-01T19:05:30Z"
          Time.parse_iso8601(txt).should eql(Time.utc(2011, 04, 01, 19, 05, 30))
        end

        it "should parse JSON time as UTC without Z" do
          txt = "2011-04-01T19:05:30"
          Time.parse_iso8601(txt).should eql(Time.utc(2011, 04, 01, 19, 05, 30))
        end

        it "should parse basic time as UTC" do
          txt = "2011-04-01 19:05:30"
          Time.parse_iso8601(txt).should eql(Time.utc(2011, 04, 01, 19, 05, 30))
        end

        it "should parse JSON time with zone" do
          txt = "2011-04-01T19:05:30 +02:00"
          Time.parse_iso8601(txt).should eql(Time.new(2011, 04, 01, 19, 05, 30, "+02:00"))
        end

        it "should parse JSON time with zone 2" do
          txt = "2011-04-01T19:05:30-0200"
          Time.parse_iso8601(txt).should eql(Time.new(2011, 04, 01, 19, 05, 30, "-02:00"))
        end

        it "should parse dodgy time with zone" do
          txt = "2011-04-01 19:05:30 +0200"
          Time.parse_iso8601(txt).should eql(Time.new(2011, 04, 01, 19, 05, 30, "+02:00"))
        end

        it "should parse dodgy time with zone 2" do
          txt = "2011-04-01 19:05:30+0230"
          Time.parse_iso8601(txt).should eql(Time.new(2011, 04, 01, 19, 05, 30, "+02:30"))
        end

        it "should parse dodgy time with zone 3" do
          txt = "2011-04-01 19:05:30 0230"
          Time.parse_iso8601(txt).should eql(Time.new(2011, 04, 01, 19, 05, 30, "+02:30"))
        end

      end

      describe "resorting back to normal parse" do
        before :each do
          Time.should_receive(:parse)
        end
        it "should work with weird time" do
          txt = "16/07/1981 05:04:00"
          Time.parse_iso8601(txt)
        end

      end
    end

  end

end
