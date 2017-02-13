require 'spec_helper'

class MigrateModel < CouchRest::Model::Base
  use_database :migrations
  proxy_database_method :id
  proxy_for :migrate_proxy_models
  property :name
  property :value
  design { view :by_name }
end

class MigrateProxyModel < CouchRest::Model::Base
  proxied_by :migrate_model
  proxy_database_method :id
  proxy_for :migrate_proxy_nested_models
  property :name
  property :value
  design { view :by_name }
end

class MigrateProxyNestedModel < CouchRest::Model::Base
  proxied_by :migrate_proxy_model
  property :name
  property :value
  design { view :by_name }
end

RSpec::Matchers.define :database_matching do |database|
  match do |actual|
    actual.server == database.server && actual.name == database.name
  end
end

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

  describe "migrations" do
    let!(:stdout) { $stdout }
    before :each do
      allow(CouchRest::Model::Base).to receive(:subclasses).and_return([MigrateModel, MigrateProxyModel, MigrateProxyNestedModel])
      $stdout = StringIO.new
    end

    after :each do
      $stdout = stdout
    end

    describe "#all_models" do
      it "should migrate root subclasses of CouchRest::Model::Base" do
        expect(MigrateModel.design_docs.first).to receive(:migrate)
        @module.all_models
      end

      it "shouldn't migrate proxied subclasses with of CouchRest::Model::Base" do
        expect(MigrateProxyModel.design_docs.first).not_to receive(:migrate)
        expect(MigrateProxyNestedModel.design_docs.first).not_to receive(:migrate)
        @module.all_models
      end

      context "migration design docs" do
        before :each do
          @module.all_models
          @design_doc = MigrateModel.design_doc
        end

        it "shouldn't modify the original design doc if activate is false" do
          @design_doc.create_view(:by_name_and_id)
          @module.all_models(activate: false)

          fetched_ddoc = MigrateModel.get(@design_doc.id)
          expect(fetched_ddoc['views']).not_to have_key('by_name_and_id')
        end

        it "should remove a leftover migration doc" do
          @design_doc.create_view(:by_name_and_value)
          @module.all_models(activate: false)

          expect(MigrateModel.get("#{@design_doc.id}_migration")).not_to be_nil
          @module.all_models
          expect(MigrateModel.get("#{@design_doc.id}_migration")).to be_nil
        end
      end
    end

    describe "#all_models_and_proxies" do
      before :each do
        # clear data from previous test runs
        MigrateModel.all.each do |mm|
          next if mm.nil?
          mm.migrate_proxy_models.all.each do |mpm|
            mpm.migrate_proxy_nested_models.database.delete! rescue nil
          end rescue nil
          mm.migrate_proxy_models.database.delete!
          mm.destroy rescue nil
        end
        MigrateModel.database.recreate!
      end

      it "should migrate first level proxied subclasses of CouchRest::Model::Base" do
        mm = MigrateModel.new(name: "Migration").save
        expect(MigrateProxyModel.design_docs.first).to receive(:migrate).with(database_matching(mm.migrate_proxy_models.database)).and_call_original
        @module.all_models_and_proxies
      end

      it "should migrate the second level proxied subclasses of CouchRest::Model::Base" do
        mm = MigrateModel.new(name: "Migration").save
        mpm = mm.migrate_proxy_models.new(name: "Migration Proxy").save
        expect(MigrateProxyNestedModel.design_docs.first).to receive(:migrate).with(database_matching(mpm.migrate_proxy_nested_models.database))
        @module.all_models_and_proxies
      end

      context "migration design docs" do
        before :each do
          @mm_instance = MigrateModel.new(name: "Migration").save
          mpm = @mm_instance.migrate_proxy_models.new(name: "Migration Proxy")

          @module.all_models_and_proxies

          @design_doc = MigrateProxyModel.design_doc
        end

        it "shouldn't modify the original design doc if activate is false" do
          @design_doc.create_view(:by_name_and_id)
          @module.all_models_and_proxies(activate: false)

          fetched_ddoc = @mm_instance.migrate_proxy_models.get(@design_doc.id)
          expect(fetched_ddoc['views']).not_to have_key('by_name_and_id')
        end

        it "should remove a leftover migration doc" do
          @design_doc.create_view(:by_name_and_value)
          @module.all_models_and_proxies(activate: false)

          expect(@mm_instance.migrate_proxy_models.get("#{@design_doc.id}_migration")).not_to be_nil
          @module.all_models_and_proxies
          expect(@mm_instance.migrate_proxy_models.get("#{@design_doc.id}_migration")).to be_nil
        end
      end
    end
  end
end
