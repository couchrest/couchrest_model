# encoding: utf-8

require 'spec_helper'

describe CouchRest::Model::Design do

  before :all do
    reset_test_db!
  end

  class DesignSampleModelBase < CouchRest::Model::Base
    use_database DB
    property :name
    property :surname
    design do
      view :by_name
    end
    design :stats do
      view :by_surname
    end
  end

  class DesignSampleModel < DesignSampleModelBase
  end

  describe "class methods" do

    before :all do
      @klass = CouchRest::Model::Design
    end

    describe ".method_name" do
      it "should return standard method name" do
        expect(@klass.method_name).to eql('design_doc')
      end

      it "should add prefix to standard method name" do
        expect(@klass.method_name('stats')).to eql('stats_design_doc')
      end
    end

  end

  describe "base methods" do

    before :each do
      @model = double("ModelExample")
      allow(@model).to receive(:to_s).and_return("ModelExample")
      @obj = CouchRest::Model::Design.new(@model)
    end


    describe "initialisation without prefix" do
      it "should associate model and set method name" do
        expect(@obj.model).to eql(@model)
        expect(@obj.method_name).to eql("design_doc")
      end

      it "should generate correct id" do
        expect(@obj['_id']).to eql("_design/ModelExample")
      end

      it "should apply defaults" do
        expect(@obj['language']).to eql('javascript')
      end
    end

    describe "initialisation with prefix" do

      it "should associate model and set method name" do
        @obj = CouchRest::Model::Design.new(@model, 'stats')
        expect(@obj.model).to eql(@model)
        expect(@obj.method_name).to eql("stats_design_doc")
      end

      it "should generate correct id with prefix" do
        @obj = CouchRest::Model::Design.new(@model, 'stats')
        expect(@obj['_id']).to eql("_design/ModelExample_stats")
      end

    end



    describe "#sync and #sync!" do

      it "should skip if auto update disabled" do
        @obj.auto_update = false
        expect(@obj).not_to receive(:sync!)
        @obj.sync
      end

      describe "with real model" do

        before :all do
          reset_test_db!
          @mod = DesignSampleModel
          @doc = @mod.design_doc
          @db  = @mod.database
        end

        it "should not have been saved up until sync called" do
          expect(@mod.database.get(@doc['_id'])).to be_nil
        end


        it "should save a design that is in cache and has changed" do
          @doc.sync # put in cache
          @doc['views']['all']['map'] += '// comment'
          # This would fail if changes were not detected!
          @doc.sync
          doc = @db.get(@doc['_id'])
          expect(doc['views']['all']['map']).to eql(@doc['views']['all']['map'])
        end

        it "should not save a design that is not in cache and has not changed" do
          @doc.sync # put doc in cache
          @doc.send(:set_cache_checksum, @doc.database, nil)

          expect(@db).not_to receive(:save_doc)
          expect(@doc).to receive(:set_cache_checksum)
          @doc.sync
        end

        it "should not reload a design that is in cache and has not changed" do
          @doc.sync
          expect(@doc).not_to receive(:load_from_database)
          @doc.sync
        end

        it "should be re-created if database destroyed" do
          @doc.sync  # saved
          reset_test_db!
          expect(@db).to receive(:save_doc).with(@doc)
          @doc.sync
        end

        it "should not update the local design definition" do
          @doc.sync!
          doc = @db.get(@doc['_id'])
          doc['views']['test'] = {'map' => "function(d) { if (d) { emit(d._id, null); } }"}
          @db.save_doc(doc)
          @doc.send(:set_cache_checksum, @doc.database, nil)
          @doc.sync
          expect(@doc['views']).not_to have_key('test')
          expect(@doc['_rev']).to be_nil
        end

        it "should save a non existant design" do
          begin
            doc = @db.get(@doc['_id'])
          rescue
            doc = nil
          end
          @db.delete_doc(doc) if doc
          @doc.sync!
          doc = @db.get(@doc['_id'])
          expect(doc).not_to be_nil
          expect(doc['views']['all']).to eql(@doc['views']['all'])
        end

      end
    end



    describe "#checksum" do

      before :all do
        @mod = DesignSampleModel
        @doc = @mod.design_doc
      end

      it "should return fresh checksum when not calculated earlier" do
        expect(@doc.checksum).not_to be_blank
      end

      it "should provide same checksum without refresh on re-request" do
        chk = @doc.checksum
        expect(@doc).not_to receive(:checksum!)
        expect(@doc.checksum).to eql(chk)
      end

      it "should provide new checksum if the design has changed" do
        chk = @doc.checksum
        @doc['views']['all']['map'] += '// comment'
        expect(@doc.checksum).not_to eql(chk)
      end

    end

    describe "database" do
      it "should provide model's database" do
        @mod = DesignSampleModel
        @doc = @mod.design_doc
        expect(@mod).to receive(:database)
        @doc.database
      end
    end


    describe "#uri" do
      it "should provide complete url" do
        @doc = DesignSampleModel.design_doc
        expect(@doc.uri).to eql("#{DesignSampleModel.database.root}/_design/DesignSampleModel")
      end
    end

    describe "#view" do
      it "should instantiate a new view and pass options" do
        expect(CouchRest::Model::Designs::View).to receive(:new).with(@obj, @model, {}, 'by_test')
        @obj.view('by_test', {})
      end
    end

    describe "#view_names" do
      it "should provide a list of all the views available" do
        @doc = DesignSampleModel.design_doc
        expect(@doc.view_names).to eql(['by_name', 'all'])
      end
    end

    describe "#has_view?" do
      before :each do
        @doc = DesignSampleModel.design_doc
      end

      it "should tell us if a view exists" do
        expect(@doc.has_view?('by_name')).to be_truthy
      end

      it "should tell us if a view exists as symbol" do
        expect(@doc.has_view?(:by_name)).to be_truthy
      end

      it "should tell us if a view does not exist" do
        expect(@doc.has_view?(:by_foobar)).to be_falsey
      end
    end

    describe "#create_view" do
      before :each do
        @doc = DesignSampleModel.design_doc
        @doc['views'] = @doc['views'].clone
      end

      it "should forward view creation to View model" do
        expect(CouchRest::Model::Designs::View).to receive(:define_and_create).with(@doc, 'by_other_name', {})
        @doc.create_view('by_other_name')
      end

      it "should forward view creation to View model with opts" do
        expect(CouchRest::Model::Designs::View).to receive(:define_and_create).with(@doc, 'by_other_name', {:by => 'name'})
        @doc.create_view('by_other_name', :by => 'name')
      end
    end


    describe "#create_filter" do
      before :each do
        @doc = DesignSampleModel.design_doc
      end

      it "should add simple filter" do
        @doc.create_filter('test', 'foobar')
        expect(@doc['filters']['test']).to eql('foobar')
        @doc['filters'] = nil # cleanup
      end
    end

    describe "#create_view_lib" do
      before :each do
        @doc = DesignSampleModel.design_doc
      end

      it "should add simple view lib" do
        @doc.create_view_lib('test', 'foobar')
        expect(@doc['views']['lib']['test']).to eql('foobar')
        @doc['views']['lib'] = nil # cleanup
      end
    end
  end


  describe "Checksum calculations" do

    it "should calculate a consistent checksum for model" do
      #WithTemplateAndUniqueID.design_doc.checksum.should eql('caa2b4c27abb82b4e37421de76d96ffc')
      expect(WithTemplateAndUniqueID.design_doc.checksum).to eql('7f44e88afbce06204010c49b76f31bcf')
    end

    it "should calculate checksum for complex model" do
      #Article.design_doc.checksum.should eql('70dff8caea143bf40fad09adf0701104')
      expect(Article.design_doc.checksum).to eql('81f6553c44ecc3fe12a39331b0cdee46')
    end

    it "should cache the generated checksum value" do
      Article.design_doc.checksum
      expect(Article.design_doc['couchrest-hash']).not_to be_blank
      Article.first
    end

  end


end
