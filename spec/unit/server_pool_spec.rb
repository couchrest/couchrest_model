
require "spec_helper"

describe CouchRest::Model::ServerPool do

  subject { CouchRest::Model::ServerPool }

  describe ".instance" do

    it "should provide a singleton" do 
      expect(subject.instance).to be_a(CouchRest::Model::ServerPool)
    end

  end

  describe "#[url]" do

    it "should provide a server object" do
      srv = subject.instance[COUCHHOST]
      expect(srv).to be_a(CouchRest::Server)
    end

    it "should always provide same object" do
      srv = subject.instance[COUCHHOST]
      srv2 = subject.instance[COUCHHOST]
      expect(srv.object_id).to eql(srv2.object_id)
    end

  end

end
