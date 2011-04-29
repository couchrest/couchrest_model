# encoding: utf-8
require File.expand_path('../../spec_helper', __FILE__)

describe CouchRest::Model::Base do

  before do
    @class = Class.new(CouchRest::Model::Base)
  end

  describe "instance methods" do
    before :each do
      @obj = @class.new
    end

    describe "#database" do
      it "should respond to" do
        @obj.should respond_to(:database)
      end
      it "should provided class's database" do
        @obj.class.should_receive :database
        @obj.database
      end
    end

    describe "#server" do
      it "should respond to method" do
        @obj.should respond_to(:server)
      end
      it "should return class's server" do
        @obj.class.should_receive :server
        @obj.server
      end
    end
  end

  describe "class methods" do

    describe ".use_database" do
      it "should respond to" do
        @class.should respond_to(:use_database)
      end
    end

    describe ".database" do
      it "should respond to" do
        @class.should respond_to(:database)
      end
      it "should provide a database object" do
        @class.database.should be_a(CouchRest::Database)
      end
      it "should provide a database with default name" do

      end

    end

    describe ".server" do
      it "should respond to" do
        @class.should respond_to(:server)
      end
      it "should provide a server object" do
        @class.server.should be_a(CouchRest::Server)
      end
      it "should provide a server with default config" do
        @class.server.uri.should eql("http://localhost:5984")
      end
      it "should allow the configuration to be overwritten" do
        @class.connection = {
            :protocol => "https",
            :host => "127.0.0.1",
            :port => '5985',
            :prefix => 'sample',
            :suffix => 'test',
            :username => 'foo',
            :password => 'bar'
          }
        @class.server.uri.should eql("https://foo:bar@127.0.0.1:5985")
      end

    end

    describe ".prepare_database" do

      it "should respond to" do
        @class.should respond_to(:prepare_database)
      end

      it "should join the database name correctly" do
        @class.connection[:suffix] = 'db'
        db = @class.prepare_database('test')
        db.name.should eql('couchrest_test_db')
      end

    end

    describe "protected methods" do

      describe ".connection_configuration" do
        it "should provide main config by default" do
          @class.send(:connection_configuration).should eql(@class.connection)
        end
        it "should load file if available" do
          @class.connection_config_file = File.join(FIXTURE_PATH, 'config', 'couchdb.yml')
          hash = @class.send(:connection_configuration)
          hash[:protocol].should eql('https')
          hash[:host].should eql('sample.cloudant.com')
          hash[:join].should eql('_')
        end
      end

      describe ".load_connection_config_file" do
        it "should provide an empty hash if config not found" do
          @class.send(:load_connection_config_file).should eql({})
        end
        it "should load file if available" do
          @class.connection_config_file = File.join(FIXTURE_PATH, 'config', 'couchdb.yml')
          hash = @class.send(:load_connection_config_file)
          hash[:development].should_not be_nil
          @class.server.uri.should eql("https://test:user@sample.cloudant.com:443")
        end

      end

    end

  end


end
