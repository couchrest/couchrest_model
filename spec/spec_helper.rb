$VERBOSE=true

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "..", "lib"))

require "bundler/setup"
require "rubygems"
require "rspec"

#require 'oj'
require 'couchrest_model'

unless defined?(FIXTURE_PATH)
  MODEL_PATH = File.join(File.dirname(__FILE__), "fixtures", "models")
  $LOAD_PATH.unshift(MODEL_PATH)

  FIXTURE_PATH = File.join(File.dirname(__FILE__), '/fixtures')
  SCRATCH_PATH = File.join(File.dirname(__FILE__), '/tmp')

  COUCHHOST = ENV["COUCH_HOST"] || "http://127.0.0.1:5984"
  TESTDB    = 'couchrest-model-test'
  TEST_SERVER    = CouchRest.new COUCHHOST
  # TEST_SERVER.default_database = TESTDB
  DB = TEST_SERVER.database(TESTDB)
end

RSpec.configure do |config|
  config.before(:suite) do
    couch_uri = URI.parse(ENV['COUCH_HOST'] || "http://127.0.0.1:5984")
    CouchRest::Model::Base.configure do |config|
      config.connection  = {
        :protocol => couch_uri.scheme,
        :host     => couch_uri.host,
        :port     => couch_uri.port,
        :username => couch_uri.user,
        :password => couch_uri.password,
        :prefix   => "couchrest",
        :join     => "_"
      }
    end
  end

  config.before(:all) { reset_test_db! }

  config.after(:all) do
    cr = TEST_SERVER
    test_dbs = cr.databases.select { |db| db =~ /^#{TESTDB}/ }
    test_dbs.each do |db|
      cr.database(db).delete! rescue nil
    end
  end
end

# Require each of the fixture models
Dir[ File.join(MODEL_PATH, "*.rb") ].sort.each { |file| require File.basename(file) }

class Basic < CouchRest::Model::Base
  use_database DB
end

def reset_test_db!
  DB.recreate! rescue nil 
  # Reset the Design Cache
  Thread.current[:couchrest_design_cache] = {}
  DB
end


def couchdb_lucene_available?
  lucene_path = "http://localhost:5985/"
  url = URI.parse(lucene_path)
  req = Net::HTTP::Get.new(url.path)
  res = Net::HTTP.new(url.host, url.port).start { |http| http.request(req) }
  true
 rescue Exception => e
  false
end

