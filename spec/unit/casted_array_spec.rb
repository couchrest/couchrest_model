# encoding: utf-8
require "spec_helper"

#
# TODO This requires much more testing, although most of the basics
# are checked by other parts of the code.
#

describe CouchRest::Model::CastedArray do

  let :klass do
    CouchRest::Model::CastedArray
  end

  describe "#initialize" do
    it "should set the casted properties" do
      prop   = double('Property')
      parent = double('Parent')
      obj = klass.new([], prop, parent)
      obj.casted_by_property.should eql(prop)
      obj.casted_by.should eql(parent)
      obj.should be_empty
    end
  end

  describe "#as_couch_json" do
    let :property do
      CouchRest::Model::Property.new(:cat, :type => Cat)
    end
    let :obj do
      klass.new([
        { :name => 'Felix' },
        { :name => 'Garfield' }
      ], property)
    end
    it "should return an array" do
      obj.as_couch_json.should be_a(Array)
    end
    it "should call as_couch_json on each value" do
      obj.first.should_receive(:as_couch_json)
      obj.as_couch_json
    end
    it "should return value if no as_couch_json method" do
      obj = klass.new(['Felix', 'Garfield'], CouchRest::Model::Property.new(:title, :type => String))
      obj.first.should_not respond_to(:as_couch_json)
      obj.as_couch_json.first.should eql('Felix')
    end

  end
end
