
require "spec_helper"

describe CouchRest::Model::ConnectionConfig do

  subject { CouchRest::Model::ConnectionConfig }

  describe ".instance" do

    it "should provide a singleton" do 
      expect(subject.instance).to be_a(CouchRest::Model::ConnectionConfig)
    end

  end

  describe "#[file]" do

    let :file do
      File.join(FIXTURE_PATH, "config", "couchdb.yml")
    end

    it "should provide a config file hash" do
      conf = subject.instance[file]
      expect(conf).to be_a(Hash)
    end

    it "should provide a config file hash with symbolized keys" do
      conf = subject.instance[file]
      expect(conf[:development]).to be_a(Hash)
      expect(conf[:development]['host']).to be_a(String)
    end

    it "should always provide same hash" do
      f1 = subject.instance[file]
      f2 = subject.instance[file]
      expect(f1.object_id).to eql(f2.object_id)
    end

  end

end
