
require 'spec_helper'

describe CouchRest::Model::Designs::Migrations do

  before :all do
    reset_test_db!
  end

  describe "base methods" do

    describe "#migrate" do
      # WARNING! ORDER IS IMPORTANT!

      describe "with limited changes" do

        class MigrationModelBase < CouchRest::Model::Base
          use_database DB
          property :name
          property :surname
          design do
            view :by_name
          end
        end

        class DesignSampleModelMigrate < MigrationModelBase
        end

        before :all do
          reset_test_db!
          @mod = DesignSampleModelMigrate
          @doc = @mod.design_doc
          @db  = @mod.database
        end

        it "should create new design if non exists" do
          @db.should_receive(:view).with("#{@doc.name}/#{@doc['views'].keys.first}", {:limit => 1, :stale => 'ok', :reduce => false})
          callback = @doc.migrate do |res|
            res.should eql(:created)
          end
          doc = @db.get(@doc['_id'])
          doc['views']['all'].should eql(@doc['views']['all'])
          callback.should be_nil
        end

        it "should not change anything if design is up to date" do
          @doc.sync
          @db.should_not_receive(:view)
          callback = @doc.migrate do |res|
            res.should eql(:no_change)
          end
          callback.should be_nil
        end

      end

      describe "migrating a document if there are changes" do

        class DesignSampleModelMigrate2 < MigrationModelBase
        end

        before :all do
          reset_test_db!
          @mod = DesignSampleModelMigrate2
          @doc = @mod.design_doc
          @db  = @mod.database
          @doc.sync!
          @doc.create_view(:by_name_and_surname)
          @doc_id = @doc['_id'] + '_migration'
        end

        it "should save new migration design doc" do
          @db.should_receive(:view).with("#{@doc.name}_migration/by_name", {:limit => 1, :reduce => false, :stale => 'ok'})
          @callback = @doc.migrate do |res|
            res.should eql(:migrated)
          end
          @callback.should_not be_nil

          # should not have updated original view until cleanup
          doc = @db.get(@doc['_id'])
          doc['views'].should_not have_key('by_name_and_surname')

          # Should have created the migration
          new_doc = @db.get(@doc_id)
          new_doc.should_not be_nil

          # should be possible to perform cleanup
          @callback.call
          lambda { new_doc = @db.get(@doc_id) }.should raise_error RestClient::ResourceNotFound

          doc = @db.get(@doc['_id'])
          doc['views'].should have_key('by_name_and_surname')
        end

      end

    end

  end
end
