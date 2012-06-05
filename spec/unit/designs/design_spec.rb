# encoding: utf-8

require 'spec_helper'

describe CouchRest::Model::Designs::Design do

  before :all do
    reset_test_db!
  end

  class DesignSampleModel < CouchRest::Model::Base
    property :name
    property :surname
    design do
      view :by_name
    end
    design :stats do
      view :by_surname
    end
  end

  describe "base methods" do

    before :each do
      @model = mock("ModelExample")
      @model.stub(:to_s).and_return("ModelExample")
      @obj = CouchRest::Model::Designs::Design.new(@model)
    end


    describe "initialisation without prefix" do
      it "should associate model" do
        @obj.model.should eql(@model)
      end

      it "should generate correct id" do
        @obj['_id'].should eql("_design/ModelExample")
      end

      it "should apply defaults" do
        @obj['language'].should eql('javascript')
      end
    end

    describe "initialisation with prefix" do

      it "should associate model" do
        @obj.model.should eql(@model)
      end

      it "should generate correct id with prefix" do
        @obj = CouchRest::Model::Designs::Design.new(@model, 'stats')
        @obj['_id'].should eql("_design/ModelExample_stats")
      end

    end


    describe "view method" do

      it "should instantiate a new view and pass options" do
        CouchRest::Model::Designs::View.should_receive(:new).with(@obj, @model, {}, 'by_test')
        @obj.view('by_test', {})
      end

    end


    describe "sync method" do

      it "should skip if auto update disabled" do
        @obj.auto_update = false
        @obj.should_not_receive(:database)
        @obj.sync
      end

      describe "with real model" do

        before :all do
          @mod = DesignSampleModel
          @doc = @mod.design_doc
          @db  = @mod.database
        end

        it "should save a non existant design" do
          begin
            doc = @db.get(@doc['_id'])
          rescue
            doc = nil
          end
          @db.delete_doc(doc) if doc
          @doc.sync
          doc = @db.get(@doc['_id'])
          doc.should_not be_nil
          doc['views']['all'].should eql(@doc['views']['all'])
        end

        it "should not save a design that is not in cache and has not changed" do
          @doc.sync # put doc in cache
          @doc.send(:set_cache_checksum, @doc.database, nil)

          @db.should_not_receive(:save_doc)
          @doc.should_receive(:set_cache_checksum)
          @doc.sync
        end

        it "should not reload a design that is in cache and has not changed" do
          @doc.sync
          @doc.should_not_receive(:load_from_database)
          @doc.sync
        end

        it "should save a design that is in cache and has changed" do
          @doc.sync # put in cache
          @doc['views']['all']['map'] += '// comment'
          # This would fail if changes were not detected!
          @doc.sync
          doc = @db.get(@doc['_id'])
          doc['views']['all']['map'].should eql(@doc['views']['all']['map'])
        end

        it "should not update the local design definition" do
          @doc.sync
          doc = @db.get(@doc['_id'])
          doc['views']['test'] = {'map' => "function(d) { if (d) { emit(d._id, null); } }"}
          @db.save_doc(doc)
          @doc.send(:set_cache_checksum, @doc.database, nil)
          @doc.sync
          @doc['views'].should_not have_key('test')
        end

      end

    end

  end


  describe "Checksum calculations" do

    it "should calculate a consistent checksum for model" do
      #WithTemplateAndUniqueID.design_doc.checksum.should eql('caa2b4c27abb82b4e37421de76d96ffc')
      WithTemplateAndUniqueID.design_doc.checksum.should eql('f0973aaa72e4db0efeb2a281ea297cec')
    end

    it "should calculate checksum for complex model" do
      #Article.design_doc.checksum.should eql('70dff8caea143bf40fad09adf0701104')
      Article.design_doc.checksum.should eql('7ef39bffdf5837e8b078411ac417d860')
    end

    it "should cache the generated checksum value" do
      Article.design_doc.checksum
      Article.design_doc['couchrest-hash'].should_not be_blank
      Article.first
    end

  end


end
