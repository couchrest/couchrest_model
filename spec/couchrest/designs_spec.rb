require File.expand_path("../../spec_helper", __FILE__)

class DesignModel < CouchRest::Model::Base
  
end

describe "Design" do

  it "should accessable from model" do
    DesignModel.respond_to?(:design).should be_true
  end

  describe ".design" do
   
    it "should instantiate a new DesignMapper" do
      CouchRest::Model::Designs::DesignMapper.should_receive(:new).and_return(DesignModel)
      DesignModel.design() { }
    end

    it "should instantiate a new DesignMapper with model" do
      CouchRest::Model::Designs::DesignMapper.should_receive(:new).with(DesignModel).and_return(DesignModel)
      DesignModel.design() { }
    end

    it "should allow methods to be called in mapper" do
      model = mock('Foo')
      model.should_receive(:foo)
      CouchRest::Model::Designs::DesignMapper.stub!(:new).and_return(model)
      DesignModel.design { foo }
    end

    it "should request a design refresh" do
      DesignModel.should_receive(:req_design_doc_refresh)
      DesignModel.design() { }
    end

  end

  describe "DesignMapper" do
    
    before :all do
      @klass = CouchRest::Model::Designs::DesignMapper
    end

    it "should initialize and set model" do
      object = @klass.new(DesignModel)
      object.send(:model).should eql(DesignModel)
    end

    describe "#view" do

      before :each do
        @object = @klass.new(DesignModel)
      end

      it "should call create method on view" do
        CouchRest::Model::Designs::View.should_receive(:create).with(DesignModel, 'test', {})
        @object.view('test')
      end

      it "should create a method on parent model" do
        CouchRest::Model::Designs::View.stub!(:create)
        @object.view('test_view')
        DesignModel.should respond_to(:test_view)
      end

      it "should create a method that returns view instance" do
        CouchRest::Model::Designs::View.stub!(:create)
        @object.view('test_view')
        CouchRest::Model::Designs::View.should_receive(:new).with(DesignModel, {}, 'test_view').and_return(nil)
        DesignModel.test_view
      end

    end

  end

end
