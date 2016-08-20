# encoding: utf-8
require "spec_helper"

describe CouchRest::Model::Configuration do

  before do
    @class = Class.new(CouchRest::Model::Base)
  end

  describe '.configure' do
    it "should set a configuration parameter" do
      @class.add_config :foo_bar
      @class.configure do |config|
        config.foo_bar = 'monkey'
      end
      expect(@class.foo_bar).to eq('monkey')
    end
  end

  describe '.add_config' do
    
    it "should add a class level accessor" do
      @class.add_config :foo_bar
      @class.foo_bar = 'foo'
      expect(@class.foo_bar).to eq('foo')
    end
    
    ['foo', :foo, 45, ['foo', :bar]].each do |val|
      it "should be inheritable for a #{val.class}" do
        @class.add_config :foo_bar
        @child_class = Class.new(@class)

        @class.foo_bar = val
        expect(@class.foo_bar).to eq(val)
        expect(@child_class.foo_bar).to eq(val)

        @child_class.foo_bar = "bar"
        expect(@child_class.foo_bar).to eq("bar")

        expect(@class.foo_bar).to eq(val)
      end
    end
    
    
    it "should add an instance level accessor" do
      @class.add_config :foo_bar
      @class.foo_bar = 'foo'
      expect(@class.new.foo_bar).to eq('foo')
    end
    
    it "should add a convenient in-class setter" do
      @class.add_config :foo_bar
      @class.foo_bar "monkey"
      expect(@class.foo_bar).to eq("monkey")
    end
  end

  describe "General examples" do

    before(:all) do
      @default_model_key = 'model-type'
    end


    it "should be possible to override on class using configure method" do
      default_model_key = Cat.model_type_key
      Cat.instance_eval do
        model_type_key 'cat-type'
      end
      expect(CouchRest::Model::Base.model_type_key).to eql(default_model_key)
      expect(Cat.model_type_key).to eql('cat-type')
      cat = Cat.new
      expect(cat.model_type_key).to eql('cat-type')
    end
  end

end
