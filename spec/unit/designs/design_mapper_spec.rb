# encoding: utf-8

require 'spec_helper'

describe CouchRest::Model::Designs::DesignMapper do

  before :all do
    @klass = CouchRest::Model::Designs::DesignMapper
  end

  describe 'initialize without prefix' do

    before :all do
      @object = @klass.new(DesignModel)
    end

    it "should set basic variables" do
      @object.send(:model).should eql(DesignModel)
      @object.send(:prefix).should be_nil
      @object.send(:method).should eql('design_doc')
    end

    it "should add design doc to list" do
      @object.model.design_docs.should include(@object.model.design_doc)
    end

    it "should create a design doc method" do
      @object.model.should respond_to('design_doc')
      @object.design_doc.should eql(@object.model.design_doc)
    end

    it "should use default for autoupdate" do
      @object.design_doc.auto_update.should be_true
    end

  end

  describe 'initialize with prefix' do
    before :all do
      @object = @klass.new(DesignModel, 'stats')
    end

    it "should set basics" do
      @object.send(:model).should eql(DesignModel)
      @object.send(:prefix).should eql('stats')
      @object.send(:method).should eql('stats_design_doc')
    end

    it "should add design doc to list" do
      @object.model.design_docs.should include(@object.model.stats_design_doc)
    end

    it "should not create an all method" do
      @object.model.should_not respond_to('all')
    end

    it "should create a design doc method" do
      @object.model.should respond_to('stats_design_doc')
      @object.design_doc.should eql(@object.model.stats_design_doc)
    end

  end

  describe "#disable_auto_update" do
    it "should disable auto updates" do
      @object = @klass.new(DesignModel)
      @object.disable_auto_update
      @object.design_doc.auto_update.should be_false
    end
  end

  describe "#enable_auto_update" do
    it "should enable auto updates" do
      @object = @klass.new(DesignModel)
      @object.enable_auto_update
      @object.design_doc.auto_update.should be_true
    end
  end

  describe "#model_type_key" do
    it "should return models type key" do
      @object = @klass.new(DesignModel)
      @object.model_type_key.should eql(@object.model.model_type_key)
    end
  end

  describe "#view" do

    before :each do
      @object = @klass.new(DesignModel)
    end

    it "should call create method on view" do
      CouchRest::Model::Designs::View.should_receive(:define).with(@object.design_doc, 'test', {})
      @object.view('test')
    end

    it "should create a method on parent model" do
      CouchRest::Model::Designs::View.stub!(:define)
      @object.view('test_view')
      DesignModel.should respond_to(:test_view)
    end

    it "should create a method for view instance" do
      @object.design_doc.should_receive(:create_view).with('test', {})
      @object.view('test')
    end
  end

  describe "#filter" do

    before :each do
      @object = @klass.new(DesignModel)
    end

    it "should add the provided function to the design doc" do
      @object.filter(:important, "function(doc, req) { return doc.priority == 'high'; }")
      DesignModel.design_doc['filters'].should_not be_empty
      DesignModel.design_doc['filters']['important'].should_not be_blank
    end
  end

  describe "#view_lib" do
    before :each do
      @object = @klass.new(DesignModel)
    end

    it "should add the #view_lib function to the design doc" do
      val = "exports.bar = 42;"
      @object.view_lib(:foo, val)
      DesignModel.design_doc['views']['lib'].should_not be_empty
      DesignModel.design_doc['views']['lib'].should_not be_blank
      DesignModel.design_doc['views']['lib']['foo'].should eql(val)
    end
  end

end

