# encoding: utf-8
require 'spec_helper'

describe CouchRest::Model::Connection do

  before do
    @class = Class.new(CouchRest::Model::Base)
  end

  describe "instance methods" do
    before :each do
      @obj = @class.new
    end

    describe "#database" do
      it "should respond to" do
        expect(@obj).to respond_to(:database)
      end
      it "should provided class's database" do
        expect(@obj.class).to receive :database
        @obj.database
      end
    end

    describe "#server" do
      it "should respond to method" do
        expect(@obj).to respond_to(:server)
      end
      it "should return class's server" do
        expect(@obj.class).to receive :server
        @obj.server
      end
    end
  end

  describe "default configuration" do

    it "should provide environment" do
      expect(@class.environment).to eql(:development)
    end
    it "should provide connection config file" do
      expect(@class.connection_config_file).to eql(File.join(Dir.pwd, 'config', 'couchdb.yml'))
    end
    it "should provided simple connection details" do
      expect(@class.connection[:prefix]).to eql('couchrest')
    end

  end

  describe "class methods" do

    describe ".use_database" do
      it "should respond to" do
        expect(@class).to respond_to(:use_database)
      end
      it "should set the database if object provided" do
        db = @class.server.database('test')
        @class.use_database(db)
        expect(@class.database).to eql(db)
      end
      it "should never prepare the database before it is needed" do
        db = @class.server.database('test')
        expect(@class).not_to receive(:prepare_database)
        @class.use_database('test')
        @class.use_database(db)
      end
      it "should use the database specified" do
        @class.use_database(:test)
        expect(@class.database.name).to eql('couchrest_test')
      end
    end

    describe ".database" do
      it "should respond to" do
        expect(@class).to respond_to(:database)
      end
      it "should provide a database object" do
        expect(@class.database).to be_a(CouchRest::Database)
      end
      it "should provide a database with default name" do
        expect(@class.database.name).to eql('couchrest')
      end
    end

    describe ".server" do
      it "should respond to" do
        expect(@class).to respond_to(:server)
      end
      it "should provide a server object" do
        expect(@class.server).to be_a(CouchRest::Server)
      end
      it "should provide a server with default config" do
        expect(@class.server.uri.to_s).to eql(CouchRest::Model::Base.server.uri.to_s)
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
        expect(@class.server.uri.to_s).to eql("https://foo:bar@127.0.0.1:5985")
      end

      it "should pass through the persistent connection option" do
        @class.connection[:persistent] = false
        expect(@class.server.connection_options[:persistent]).to be_falsey
      end

    end

    describe ".prepare_database" do
      it "should respond to" do
        expect(@class).to respond_to(:prepare_database)
      end

      it "should join the database name correctly" do
        @class.connection[:suffix] = 'db'
        db = @class.prepare_database('test')
        expect(db.name).to eql('couchrest_test_db')
      end

      it "should ignore nil values in database name" do
        @class.connection[:suffix] = nil
        db = @class.prepare_database('test')
        expect(db.name).to eql('couchrest_test')
      end

      it "should use the .use_database value" do
        @class.use_database('testing')
        db = @class.prepare_database
        expect(db.name).to eql('couchrest_testing')
      end

      it "should ignore the .use_database value when overrride" do
        @class.use_database('testing')
        db = @class.prepare_database('test', true)
        expect(db.name).to eql('couchrest_test')
      end
    end

    describe "protected methods" do

      describe ".connection_configuration" do
        it "should provide main config by default" do
          expect(@class.send(:connection_configuration)).to eql(@class.connection)
        end
        it "should load file if available" do
          @class.connection_config_file = File.join(FIXTURE_PATH, 'config', 'couchdb.yml')
          hash = @class.send(:connection_configuration)
          expect(hash[:protocol]).to eql('https')
          expect(hash[:host]).to eql('sample.cloudant.com')
          expect(hash[:join]).to eql('_')
        end
      end

      describe ".load_connection_config_file" do
        it "should provide an empty hash if config not found" do
          expect(@class.send(:load_connection_config_file)).to eql({})
        end
        it "should load file if available" do
          @class.connection_config_file = File.join(FIXTURE_PATH, 'config', 'couchdb.yml')
          hash = @class.send(:load_connection_config_file)
          expect(hash[:development]).not_to be_nil
          expect(@class.server.uri.to_s).to eql("https://test:user@sample.cloudant.com")
        end

      end

    end

  end


end
