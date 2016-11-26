
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
          expect(@db).to receive(:view).with("#{@doc.name}/#{@doc['views'].keys.first}", {
            :limit => 1, :stale => 'update_after', :reduce => false
          })
          callback = @doc.migrate do |res|
            expect(res).to eql(:created)
          end
          doc = @db.get(@doc['_id'])
          expect(doc['views']['all']).to eql(@doc['views']['all'])
          expect(doc['couchrest-hash']).not_to be_nil
          expect(callback).to be_nil
        end

        it "should not change anything if design is up to date" do
          @doc.sync
          expect(@db).not_to receive(:view)
          callback = @doc.migrate do |res|
            expect(res).to eql(:no_change)
          end
          expect(callback).to be_nil
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
          expect(@db).to receive(:view).with("#{@doc.name}_migration/by_name", {
            :limit => 1, :reduce => false, :stale => 'update_after'
          })
          @callback = @doc.migrate do |res|
            expect(res).to eql(:migrated)
          end
          expect(@callback).not_to be_nil

          # should not have updated original view until cleanup
          doc = @db.get(@doc['_id'])
          expect(doc['views']).not_to have_key('by_name_and_surname')

          # Should have created the migration
          new_doc = @db.get(@doc_id)
          expect(new_doc).not_to be_nil

          # should be possible to perform cleanup
          @callback.call
          expect(@db.get(@doc_id)).to be_nil

          doc = @db.get(@doc['_id'])
          expect(doc['views']).to have_key('by_name_and_surname')
        end

      end

    end

  end
end
