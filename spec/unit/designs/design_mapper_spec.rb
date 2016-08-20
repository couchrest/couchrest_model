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
      expect(@object.send(:model)).to eql(DesignModel)
      expect(@object.send(:prefix)).to be_nil
      expect(@object.send(:method)).to eql('design_doc')
    end

    it "should add design doc to list" do
      expect(@object.model.design_docs).to include(@object.model.design_doc)
    end

    it "should create a design doc method" do
      expect(@object.model).to respond_to('design_doc')
      expect(@object.design_doc).to eql(@object.model.design_doc)
    end

    it "should use default for autoupdate" do
      expect(@object.design_doc.auto_update).to be_truthy
    end

  end

  describe 'initialize with prefix' do
    before :all do
      @object = @klass.new(DesignModel, 'stats')
    end

    it "should set basics" do
      expect(@object.send(:model)).to eql(DesignModel)
      expect(@object.send(:prefix)).to eql('stats')
      expect(@object.send(:method)).to eql('stats_design_doc')
    end

    it "should add design doc to list" do
      expect(@object.model.design_docs).to include(@object.model.stats_design_doc)
    end

    it "should not create an all method" do
      expect(@object.model).not_to respond_to('all')
    end

    it "should create a design doc method" do
      expect(@object.model).to respond_to('stats_design_doc')
      expect(@object.design_doc).to eql(@object.model.stats_design_doc)
    end

  end

  describe "#disable_auto_update" do
    it "should disable auto updates" do
      @object = @klass.new(DesignModel)
      @object.disable_auto_update
      expect(@object.design_doc.auto_update).to be_falsey
    end
  end

  describe "#enable_auto_update" do
    it "should enable auto updates" do
      @object = @klass.new(DesignModel)
      @object.enable_auto_update
      expect(@object.design_doc.auto_update).to be_truthy
    end
  end

  describe "#model_type_key" do
    it "should return models type key" do
      @object = @klass.new(DesignModel)
      expect(@object.model_type_key).to eql(@object.model.model_type_key)
    end
  end

  describe "#view" do

    before :each do
      @object = @klass.new(DesignModel)
    end

    it "should call create method on view" do
      expect(CouchRest::Model::Designs::View).to receive(:define).with(@object.design_doc, 'test', {})
      @object.view('test')
    end

    it "should create a method on parent model" do
      allow(CouchRest::Model::Designs::View).to receive(:define)
      @object.view('test_view')
      expect(DesignModel).to respond_to(:test_view)
    end

    it "should create a method for view instance" do
      expect(@object.design_doc).to receive(:create_view).with('test', {})
      @object.view('test')
    end
  end

  describe "#filter" do

    before :each do
      @object = @klass.new(DesignModel)
    end

    it "should add the provided function to the design doc" do
      @object.filter(:important, "function(doc, req) { return doc.priority == 'high'; }")
      expect(DesignModel.design_doc['filters']).not_to be_empty
      expect(DesignModel.design_doc['filters']['important']).not_to be_blank
    end
  end

  describe "#view_lib" do
    before :each do
      @object = @klass.new(DesignModel)
    end

    it "should add the #view_lib function to the design doc" do
      val = "exports.bar = 42;"
      @object.view_lib(:foo, val)
      expect(DesignModel.design_doc['views']['lib']).not_to be_empty
      expect(DesignModel.design_doc['views']['lib']).not_to be_blank
      expect(DesignModel.design_doc['views']['lib']['foo']).to eql(val)
    end
  end

end

