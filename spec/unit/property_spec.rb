# encoding: utf-8
require 'spec_helper'

describe CouchRest::Model::Property do

  let :klass do
    CouchRest::Model::Property
  end

  it "should provide name as string" do
    property = CouchRest::Model::Property.new(:test, :type => String)
    property.name.should eql('test')
    property.to_s.should eql('test')
  end

  it "should provide name as a symbol" do 
    property = CouchRest::Model::Property.new(:test, :type => String)
    property.name.to_sym.should eql(:test)
    property.to_sym.should eql(:test)
  end

  it "should provide class from type" do
    property = CouchRest::Model::Property.new(:test, :type => String)
    property.type.should eql(String)
    property.array.should be_false
  end

  it "should provide base class from type in array" do
    property = CouchRest::Model::Property.new(:test, :type => [String])
    property.type.should eql(String)
    property.array.should be_true
  end

  it "should provide base class and set array type" do
    property = CouchRest::Model::Property.new(:test, :type => String, :array => true)
    property.type.should eql(String)
    property.array.should be_true
  end

  it "should raise error if type as string requested" do
    expect {
      CouchRest::Model::Property.new(:test, :type => 'String')
    }.to raise_error(/Defining a property type as a String is not supported/)
  end

  it "should leave type nil and return class as nil also" do
    property = CouchRest::Model::Property.new(:test, :type => nil)
    property.type.should be_nil
  end

  it "should convert empty type array to [Object]" do
    property = CouchRest::Model::Property.new(:test, :type => [])
    property.type.should eql(Object)
  end

  it "should set init method option or leave as 'new'" do
    # (bad example! Time already typecast)
    property = CouchRest::Model::Property.new(:test, :type => Time)
    property.init_method.should eql('new')
    property = CouchRest::Model::Property.new(:test, :type => Time, :init_method => 'parse')
    property.init_method.should eql('parse')
  end

  it "should set the allow_blank option to true by default" do
    property = CouchRest::Model::Property.new(:test, :type => String)
    property.allow_blank.should be_true
  end

  it "should allow setting of the allow_blank option to false" do
    property = CouchRest::Model::Property.new(:test, :type => String, :allow_blank => false)
    property.allow_blank.should be_false
  end

  it "should convert block to type" do
    prop = klass.new(:test) do
      property :testing
    end
    prop.array.should be_false
    prop.type.should_not be_nil
    prop.type.class.should eql(Class)
    obj = prop.type.new
    obj.should respond_to(:testing)
  end

  it "should convert block to type with array" do
    prop = klass.new(:test, :array => true) do
      property :testing
    end
    prop.type.should_not be_nil
    prop.type.class.should eql(Class)
    prop.array.should be_true
  end

  describe "#build" do
    it "should allow instantiation of new object" do
      property = CouchRest::Model::Property.new(:test, :type => Date)
      obj = property.build(2011, 05, 21)
      obj.should eql(Date.new(2011, 05, 21))
    end
    it "should use init_method if provided" do
      property = CouchRest::Model::Property.new(:test, :type => Date, :init_method => 'parse')
      obj = property.build("2011-05-21")
      obj.should eql(Date.new(2011, 05, 21))
    end
    it "should use init_method Proc if provided" do
      property = CouchRest::Model::Property.new(:test, :type => Date, :init_method => Proc.new{|v| Date.parse(v)})
      obj = property.build("2011-05-21")
      obj.should eql(Date.new(2011, 05, 21))
    end
    it "should raise error if no class" do
      property = CouchRest::Model::Property.new(:test)
      lambda { property.build }.should raise_error(StandardError, /Cannot build/)
    end
  end

  ## Property Casting method. More thoroughly tested in typecast_spec.

  describe "casting" do
    it "should cast a value" do
      property = CouchRest::Model::Property.new(:test, :type => Date)
      parent = double("FooObject")
      property.cast(parent, "2010-06-16").should eql(Date.new(2010, 6, 16))
      property.cast_value(parent, "2010-06-16").should eql(Date.new(2010, 6, 16))
    end

    it "should cast an array of values" do
      property = CouchRest::Model::Property.new(:test, :type => [Date])
      parent = double("FooObject")
      property.cast(parent, ["2010-06-01", "2010-06-02"]).should eql([Date.new(2010, 6, 1), Date.new(2010, 6, 2)])
    end

    it "should cast an array of values with array option" do
      property = CouchRest::Model::Property.new(:test, :type => Date, :array => true)
      parent = double("FooObject")
      property.cast(parent, ["2010-06-01", "2010-06-02"]).should eql([Date.new(2010, 6, 1), Date.new(2010, 6, 2)])
    end

    context "when allow_blank is false" do
      let :parent do
        double("FooObject")
      end

      it "should convert blank to nil" do
        property = CouchRest::Model::Property.new(:test, :type => String, :allow_blank => false)
        property.cast(parent, "").should be_nil
      end

      it "should remove blank array entries" do
        property = CouchRest::Model::Property.new(:test, :type => [String], :allow_blank => false)
        property.cast(parent, ["", "foo"]).should eql(["foo"])
      end
    end

    it "should set a CastedArray on array of Objects" do
      property = CouchRest::Model::Property.new(:test, :type => [Object])
      parent = double("FooObject")
      property.cast(parent, ["2010-06-01", "2010-06-02"]).class.should eql(CouchRest::Model::CastedArray)
    end

    it "should set a CastedArray on array of Strings" do
      property = CouchRest::Model::Property.new(:test, :type => [String])
      parent = double("FooObject")
      property.cast(parent, ["2010-06-01", "2010-06-02"]).class.should eql(CouchRest::Model::CastedArray)
    end

    it "should allow instantion of model via CastedArray#build" do
      property = CouchRest::Model::Property.new(:dates, :type => [Date])
      parent = Article.new
      ary = property.cast(parent, [])
      obj = ary.build(2011, 05, 21)
      ary.length.should eql(1)
      ary.first.should eql(Date.new(2011, 05, 21))
      obj = ary.build(2011, 05, 22)
      ary.length.should eql(2)
      ary.last.should eql(Date.new(2011, 05, 22))
    end

    it "should cast an object that provides an array" do
      prop = Class.new do
        attr_accessor :ary
        def initialize(val); self.ary = val; end
        def as_json; ary; end
      end
      property = CouchRest::Model::Property.new(:test, :type => prop)
      parent = double("FooClass")
      cast = property.cast(parent, [1, 2])
      cast.ary.should eql([1, 2])
    end

    it "should set parent as casted_by object in CastedArray" do
      property = CouchRest::Model::Property.new(:test, :type => [Object])
      parent = double("FooObject")
      property.cast(parent, ["2010-06-01", "2010-06-02"]).casted_by.should eql(parent)
    end

    it "should set casted_by on new value" do
      property = CouchRest::Model::Property.new(:test, :type => CatToy)
      parent = double("CatObject")
      cast = property.cast(parent, {:name => 'catnip'})
      cast.casted_by.should eql(parent)
    end

  end

end

