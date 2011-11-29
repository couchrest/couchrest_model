# encoding: utf-8
require File.expand_path('../../../spec_helper', __FILE__)

describe "Time Parsing core extension" do

  describe "Time" do

    it "should respond to .parse_iso8601" do
      Time.respond_to?("parse_iso8601").should be_true
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
