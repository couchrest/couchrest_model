
require 'spec_helper'

describe CouchRest::Model::Utils::Migrate do

  before :each do
    @module = CouchRest::Model::Utils::Migrate
  end

  describe "#load_all_models" do
    it "should not do anything if Rails is not available" do
      @module.load_all_models
    end
    it "should detect if Rails is available and require models" do
      Rails = double()
      allow(Rails).to receive(:root).and_return("")
      expect(Dir).to receive(:[]).with("app/models/**/*.rb").and_return(['failed_require'])
      # we can't double require, so just expect an error
      expect {
        @module.load_all_models
      }.to raise_error(LoadError)
    end
  end

end
