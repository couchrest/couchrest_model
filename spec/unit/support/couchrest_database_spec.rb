require "spec_helper"

describe CouchRest::Model::Support::Database do

  describe "#delete!" do

    it "should empty design cache after a database is destroyed" do
      Thread.current[:couchrest_design_cache] = { :foo => :bar }
      DB.delete!
      expect(Thread.current[:couchrest_design_cache]).to be_empty
    end

  end

end
