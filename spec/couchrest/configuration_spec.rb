# encoding: utf-8
require File.expand_path('../../spec_helper', __FILE__)
require File.join(FIXTURE_PATH, 'more', 'cat')

describe CouchRest::Model::Base do

  before do
    @class = Class.new(CouchRest::Model::Base)
  end

  describe '.configure' do
    it "should set a configuration parameter" do
      @class.add_config :foo_bar
      @class.configure do |config|
        config.foo_bar = 'monkey'
      end
      @class.foo_bar.should == 'monkey'
    end
  end

  describe '.add_config' do
    
    it "should add a class level accessor" do
      @class.add_config :foo_bar
      @class.foo_bar = 'foo'
      @class.foo_bar.should == 'foo'
    end
    
    ['foo', :foo, 45, ['foo', :bar]].each do |val|
      it "should be inheritable for a #{val.class}" do
        @class.add_config :foo_bar
        @child_class = Class.new(@class)

        @class.foo_bar = val
        @class.foo_bar.should == val
        @child_class.foo_bar.should == val

        @child_class.foo_bar = "bar"
        @child_class.foo_bar.should == "bar"

        @class.foo_bar.should == val
      end
    end
    
    
    it "should add an instance level accessor" do
      @class.add_config :foo_bar
      @class.foo_bar = 'foo'
      @class.new.foo_bar.should == 'foo'
    end
    
    it "should add a convenient in-class setter" do
      @class.add_config :foo_bar
      @class.foo_bar "monkey"
      @class.foo_bar.should == "monkey"
    end
  end

  describe "default configuration" do

    it "should provide environment" do
      @class.environment.should eql(:development)
    end
    it "should provide connection config file" do
      @class.connection_config_file.should eql(File.join(Dir.pwd, 'config', 'couchdb.yml'))
    end
    it "should provided simple connection details" do
      @class.connection[:prefix].should eql('couchrest')
    end

  end

  describe "default configuration with Rails" do
    before do
      Rails = mock('Rails') unless defined?(Rails)
      Rails.stub!(:env).and_return(:dev)
      Rails.stub!(:root).and_return("/rails/root")
      app = mock('Application')
      app.stub!(:class).and_return("SampleCouch::Application")
      Rails.stub!(:application).and_return(app)

      # New anon class!
      @class = Class.new()
      @class.class_eval do
        include CouchRest::Model::Configuration
      end
    end

    it "should provide environment" do
      @class.environment.should eql(:dev)
    end
    it "should provide connection config file" do
      @class.connection_config_file.should eql(File.join("/rails/root", 'config', 'couchdb.yml'))
    end
    it "should provided simple connection details" do
      @class.connection[:prefix].should eql('sample_couch')
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
      CouchRest::Model::Base.model_type_key.should eql(default_model_key)
      Cat.model_type_key.should eql('cat-type')
      cat = Cat.new
      cat.model_type_key.should eql('cat-type')
    end
  end

end
