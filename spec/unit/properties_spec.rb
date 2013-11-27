# encoding: utf-8
require "spec_helper"

describe CouchRest::Model::Properties do

  before(:each) do
    @obj = WithDefaultValues.new
  end
 
  describe "multipart attributes" do
    context "with valid params" do        
      it "should parse a legal date" do
        valid_date_params = { "exec_date(1i)"=>"2011", 
                              "exec_date(2i)"=>"10", 
                              "exec_date(3i)"=>"18"}
        @obj = WithDateAndTime.new valid_date_params
        @obj.exec_date.should_not be_nil
        @obj.exec_date.should be_kind_of(Date)
        @obj.exec_date.should == Date.new(2011, 10 ,18)
      end
    
      it "should parse a legal time" do
        valid_time_params = { "exec_time(1i)"=>"2011", 
                              "exec_time(2i)"=>"10", 
                              "exec_time(3i)"=>"18",
                              "exec_time(4i)"=>"15",
                              "exec_time(5i)"=>"15",
                              "exec_time(6i)"=>"15",}
        @obj = WithDateAndTime.new valid_time_params
        @obj.exec_time.should_not be_nil
        @obj.exec_time.should be_kind_of(Time)
        @obj.exec_time.should == Time.utc(2011, 10 ,18, 15, 15, 15)
      end
    end
    
    context "with invalid params" do
      before(:each) do
        @invalid_date_params = { "exec_date(1i)"=>"2011", 
                                 "exec_date(2i)"=>"foo", 
                                 "exec_date(3i)"=>"18"}
      end
      it "should still create a model if there are invalid attributes" do
        @obj = WithDateAndTime.new @invalid_date_params
        @obj.should_not be_nil
        @obj.should be_kind_of(WithDateAndTime)
      end
      it "should not crash because of an empty value" do
        @invalid_date_params["exec_date(2i)"] = ""
        @obj = WithDateAndTime.new @invalid_date_params
        @obj.should_not be_nil
        @obj.exec_date.should_not be_kind_of(Date)
        @obj.should be_kind_of(WithDateAndTime)
      end
    end

    # Specific use case for Ruby 2.0.0
    context "with brackets in value" do
      let :klass do
        klass = Class.new(CouchRest::Model::Base)
        klass.class_eval do
          property :name, String
        end
        klass
      end

      it "should be accepted" do
        lambda {
          @obj = klass.new(:name => 'test (object)')
        }.should_not raise_error
      end

    end

  end

end

