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
        @klass.method_name.should eql('design_doc')
      end

      it "should add prefix to standard method name" do
        @klass.method_name('stats').should eql('stats_design_doc')
      end
    end

  end

  describe "base methods" do

    before :each do
      @model = mock("ModelExample")
      @model.stub(:to_s).and_return("ModelExample")
      @obj = CouchRest::Model::Design.new(@model)
    end


    describe "initialisation without prefix" do
      it "should associate model and set method name" do
        @obj.model.should eql(@model)
        @obj.method_name.should eql("design_doc")
      end

      it "should generate correct id" do
        @obj['_id'].should eql("_design/ModelExample")
      end

      it "should apply defaults" do
        @obj['language'].should eql('javascript')
      end
    end

    describe "initialisation with prefix" do

      it "should associate model and set method name" do
        @obj = CouchRest::Model::Design.new(@model, 'stats')
        @obj.model.should eql(@model)
        @obj.method_name.should eql("stats_design_doc")
      end

      it "should generate correct id with prefix" do
        @obj = CouchRest::Model::Design.new(@model, 'stats')
        @obj['_id'].should eql("_design/ModelExample_stats")
      end

    end



    describe "#sync and #sync!" do

      it "should skip if auto update disabled" do
        @obj.auto_update = false
        @obj.should_not_receive(:sync!)
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
          lambda { @mod.database.get(@doc['_id']) }.should raise_error(RestClient::ResourceNotFound)
        end


        it "should save a design that is in cache and has changed" do
          @doc.sync # put in cache
          @doc['views']['all']['map'] += '// comment'
          # This would fail if changes were not detected!
          @doc.sync
          doc = @db.get(@doc['_id'])
          doc['views']['all']['map'].should eql(@doc['views']['all']['map'])
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

        it "should be re-created if database destroyed" do
          @doc.sync  # saved
          reset_test_db!
          @db.should_receive(:save_doc).with(@doc)
          @doc.sync
        end

        it "should not update the local design definition" do
          @doc.sync!
          doc = @db.get(@doc['_id'])
          doc['views']['test'] = {'map' => "function(d) { if (d) { emit(d._id, null); } }"}
          @db.save_doc(doc)
          @doc.send(:set_cache_checksum, @doc.database, nil)
          @doc.sync
          @doc['views'].should_not have_key('test')
          @doc['_rev'].should be_nil
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
          doc.should_not be_nil
          doc['views']['all'].should eql(@doc['views']['all'])
        end

      end
    end


    describe "#migrate" do
      # WARNING! ORDER IS IMPORTANT!

      describe "with limited changes" do

        class DesignSampleModelMigrate < DesignSampleModelBase
        end

        before :all do
          reset_test_db!
          @mod = DesignSampleModelMigrate
          @doc = @mod.design_doc
          @db  = @mod.database
        end

        it "should create new design if non exists" do
          @db.should_receive(:view).with("#{@doc['_id']}/_view/#{@doc['views'].keys.first}", {:limit => 1, :reduce => false})
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

        class DesignSampleModelMigrate2 < DesignSampleModelBase
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
          @db.should_receive(:view).with("#{@doc_id}/_view/by_name", {:limit => 1, :reduce => false})
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


    describe "#checksum" do

      before :all do
        @mod = DesignSampleModel
        @doc = @mod.design_doc
      end

      it "should return fresh checksum when not calculated earlier" do
        @doc.checksum.should_not be_blank
      end

      it "should provide same checksum without refresh on re-request" do
        chk = @doc.checksum
        @doc.should_not_receive(:checksum!)
        @doc.checksum.should eql(chk)
      end

      it "should provide new checksum if the design has changed" do
        chk = @doc.checksum
        @doc['views']['all']['map'] += '// comment'
        @doc.checksum.should_not eql(chk)
      end

    end

    describe "database" do
      it "should provide model's database" do
        @mod = DesignSampleModel
        @doc = @mod.design_doc
        @mod.should_receive(:database)
        @doc.database
      end
    end


    describe "#uri" do
      it "should provide complete url" do
        @doc = DesignSampleModel.design_doc
        @doc.uri.should eql("#{DesignSampleModel.database.root}/_design/DesignSampleModel")
      end
    end

    describe "#view" do
      it "should instantiate a new view and pass options" do
        CouchRest::Model::Designs::View.should_receive(:new).with(@obj, @model, {}, 'by_test')
        @obj.view('by_test', {})
      end
    end

    describe "#view_names" do
      it "should provide a list of all the views available" do
        @doc = DesignSampleModel.design_doc
        @doc.view_names.should eql(['by_name', 'all'])
      end
    end

    describe "#has_view?" do
      before :each do
        @doc = DesignSampleModel.design_doc
      end

      it "should tell us if a view exists" do
        @doc.has_view?('by_name').should be_true
      end

      it "should tell us if a view exists as symbol" do
        @doc.has_view?(:by_name).should be_true
      end

      it "should tell us if a view does not exist" do
        @doc.has_view?(:by_foobar).should be_false
      end
    end

    describe "#create_view" do
      before :each do
        @doc = DesignSampleModel.design_doc
        @doc['views'] = @doc['views'].clone
      end

      it "should forward view creation to View model" do
        CouchRest::Model::Designs::View.should_receive(:define_and_create).with(@doc, 'by_other_name', {})
        @doc.create_view('by_other_name')
      end

      it "should forward view creation to View model with opts" do
        CouchRest::Model::Designs::View.should_receive(:define_and_create).with(@doc, 'by_other_name', {:by => 'name'})
        @doc.create_view('by_other_name', :by => 'name')
      end
    end


    describe "#create_filter" do
      before :each do
        @doc = DesignSampleModel.design_doc
      end

      it "should add simple filter" do
        @doc.create_filter('test', 'foobar')
        @doc['filters']['test'].should eql('foobar')
        @doc['filters'] = nil # cleanup
      end
    end

    describe "#create_view_lib" do
      before :each do
        @doc = DesignSampleModel.design_doc
      end

      it "should add simple view lib" do
        @doc.create_view_lib('test', 'foobar')
        @doc['views']['lib']['test'].should eql('foobar')
        @doc['views']['lib'] = nil # cleanup
      end
    end
  end


  describe "Checksum calculations" do

    it "should calculate a consistent checksum for model" do
      #WithTemplateAndUniqueID.design_doc.checksum.should eql('caa2b4c27abb82b4e37421de76d96ffc')
      WithTemplateAndUniqueID.design_doc.checksum.should eql('7f44e88afbce06204010c49b76f31bcf')
    end

    it "should calculate checksum for complex model" do
      #Article.design_doc.checksum.should eql('70dff8caea143bf40fad09adf0701104')
      Article.design_doc.checksum.should eql('81f6553c44ecc3fe12a39331b0cdee46')
    end

    it "should cache the generated checksum value" do
      Article.design_doc.checksum
      Article.design_doc['couchrest-hash'].should_not be_blank
      Article.first
    end

  end


end
