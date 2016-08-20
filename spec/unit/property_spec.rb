# encoding: utf-8
require 'spec_helper'

describe CouchRest::Model::Property do

  let :klass do
    CouchRest::Model::Property
  end

  it "should provide name as string" do
    property = CouchRest::Model::Property.new(:test, :type => String)
    expect(property.name).to eql('test')
    expect(property.to_s).to eql('test')
  end

  it "should provide name as a symbol" do 
    property = CouchRest::Model::Property.new(:test, :type => String)
    expect(property.name.to_sym).to eql(:test)
    expect(property.to_sym).to eql(:test)
  end

  it "should provide class from type" do
    property = CouchRest::Model::Property.new(:test, :type => String)
    expect(property.type).to eql(String)
    expect(property.array).to be_falsey
  end

  it "should provide base class from type in array" do
    property = CouchRest::Model::Property.new(:test, :type => [String])
    expect(property.type).to eql(String)
    expect(property.array).to be_truthy
  end

  it "should provide base class and set array type" do
    property = CouchRest::Model::Property.new(:test, :type => String, :array => true)
    expect(property.type).to eql(String)
    expect(property.array).to be_truthy
  end

  it "should raise error if type as string requested" do
    expect {
      CouchRest::Model::Property.new(:test, :type => 'String')
    }.to raise_error(/Defining a property type as a String is not supported/)
  end

  it "should leave type nil and return class as nil also" do
    property = CouchRest::Model::Property.new(:test, :type => nil)
    expect(property.type).to be_nil
  end

  it "should convert empty type array to [Object]" do
    property = CouchRest::Model::Property.new(:test, :type => [])
    expect(property.type).to eql(Object)
  end

  it "should set init method option or leave as 'new'" do
    # (bad example! Time already typecast)
    property = CouchRest::Model::Property.new(:test, :type => Time)
    expect(property.init_method).to eql('new')
    property = CouchRest::Model::Property.new(:test, :type => Time, :init_method => 'parse')
    expect(property.init_method).to eql('parse')
  end

  it "should set the allow_blank option to true by default" do
    property = CouchRest::Model::Property.new(:test, :type => String)
    expect(property.allow_blank).to be_truthy
  end

  it "should allow setting of the allow_blank option to false" do
    property = CouchRest::Model::Property.new(:test, :type => String, :allow_blank => false)
    expect(property.allow_blank).to be_falsey
  end

  it "should convert block to type" do
    prop = klass.new(:test) do
      property :testing
    end
    expect(prop.array).to be_falsey
    expect(prop.type).not_to be_nil
    expect(prop.type.class).to eql(Class)
    obj = prop.type.new
    expect(obj).to respond_to(:testing)
  end

  it "should convert block to type with array" do
    prop = klass.new(:test, :array => true) do
      property :testing
    end
    expect(prop.type).not_to be_nil
    expect(prop.type.class).to eql(Class)
    expect(prop.array).to be_truthy
  end

  describe "#build" do
    it "should allow instantiation of new object" do
      property = CouchRest::Model::Property.new(:test, :type => Date)
      obj = property.build(2011, 05, 21)
      expect(obj).to eql(Date.new(2011, 05, 21))
    end
    it "should use init_method if provided" do
      property = CouchRest::Model::Property.new(:test, :type => Date, :init_method => 'parse')
      obj = property.build("2011-05-21")
      expect(obj).to eql(Date.new(2011, 05, 21))
    end
    it "should use init_method Proc if provided" do
      property = CouchRest::Model::Property.new(:test, :type => Date, :init_method => Proc.new{|v| Date.parse(v)})
      obj = property.build("2011-05-21")
      expect(obj).to eql(Date.new(2011, 05, 21))
    end
    it "should raise error if no class" do
      property = CouchRest::Model::Property.new(:test)
      expect { property.build }.to raise_error(StandardError, /Cannot build/)
    end
  end

  ## Property Casting method. More thoroughly tested in typecast_spec.

  describe "casting" do
    it "should cast a value" do
      property = CouchRest::Model::Property.new(:test, :type => Date)
      parent = double("FooObject")
      expect(property.cast(parent, "2010-06-16")).to eql(Date.new(2010, 6, 16))
      expect(property.cast_value(parent, "2010-06-16")).to eql(Date.new(2010, 6, 16))
    end

    it "should cast an array of values" do
      property = CouchRest::Model::Property.new(:test, :type => [Date])
      parent = double("FooObject")
      expect(property.cast(parent, ["2010-06-01", "2010-06-02"])).to eql([Date.new(2010, 6, 1), Date.new(2010, 6, 2)])
    end

    it "should cast an array of values with array option" do
      property = CouchRest::Model::Property.new(:test, :type => Date, :array => true)
      parent = double("FooObject")
      expect(property.cast(parent, ["2010-06-01", "2010-06-02"])).to eql([Date.new(2010, 6, 1), Date.new(2010, 6, 2)])
    end

    context "when allow_blank is false" do
      let :parent do
        double("FooObject")
      end

      it "should convert blank to nil" do
        property = CouchRest::Model::Property.new(:test, :type => String, :allow_blank => false)
        expect(property.cast(parent, "")).to be_nil
      end

      it "should remove blank array entries" do
        property = CouchRest::Model::Property.new(:test, :type => [String], :allow_blank => false)
        expect(property.cast(parent, ["", "foo"])).to eql(["foo"])
      end
    end

    it "should set a CastedArray on array of Objects" do
      property = CouchRest::Model::Property.new(:test, :type => [Object])
      parent = double("FooObject")
      expect(property.cast(parent, ["2010-06-01", "2010-06-02"]).class).to eql(CouchRest::Model::CastedArray)
    end

    it "should set a CastedArray on array of Strings" do
      property = CouchRest::Model::Property.new(:test, :type => [String])
      parent = double("FooObject")
      expect(property.cast(parent, ["2010-06-01", "2010-06-02"]).class).to eql(CouchRest::Model::CastedArray)
    end

    it "should allow instantion of model via CastedArray#build" do
      property = CouchRest::Model::Property.new(:dates, :type => [Date])
      parent = Article.new
      ary = property.cast(parent, [])
      obj = ary.build(2011, 05, 21)
      expect(ary.length).to eql(1)
      expect(ary.first).to eql(Date.new(2011, 05, 21))
      obj = ary.build(2011, 05, 22)
      expect(ary.length).to eql(2)
      expect(ary.last).to eql(Date.new(2011, 05, 22))
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
      expect(cast.ary).to eql([1, 2])
    end

    it "should set parent as casted_by object in CastedArray" do
      property = CouchRest::Model::Property.new(:test, :type => [Object])
      parent = double("FooObject")
      expect(property.cast(parent, ["2010-06-01", "2010-06-02"]).casted_by).to eql(parent)
    end

    it "should set casted_by on new value" do
      property = CouchRest::Model::Property.new(:test, :type => CatToy)
      parent = double("CatObject")
      cast = property.cast(parent, {:name => 'catnip'})
      expect(cast.casted_by).to eql(parent)
    end

  end

end

