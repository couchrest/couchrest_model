require File.expand_path("../../spec_helper", __FILE__)

class DesignModel < CouchRest::Model::Base
  
end

describe "Design" do

  it "should accessable from model" do
    DesignModel.respond_to?(:design).should be_true
  end

  describe "class methods" do

    describe ".design" do
      before :each do 
        @mapper = mock('DesignMapper')
        @mapper.stub!(:create_view_method)
      end

      it "should instantiate a new DesignMapper" do
        CouchRest::Model::Designs::DesignMapper.should_receive(:new).with(DesignModel).and_return(@mapper)
        @mapper.should_receive(:create_view_method).with(:all)
        @mapper.should_receive(:instance_eval)
        DesignModel.design() { }
      end

      it "should allow methods to be called in mapper" do
        @mapper.should_receive(:foo)
        CouchRest::Model::Designs::DesignMapper.stub!(:new).and_return(@mapper)
        DesignModel.design { foo }
      end

      it "should work even if a block is not provided" do
        lambda { DesignModel.design }.should_not raise_error
      end

    end

    describe "default_per_page" do
      it "should return 25 default" do
        DesignModel.default_per_page.should eql(25)
      end
    end

    describe ".paginates_per" do
      it "should set the default per page value" do
        DesignModel.paginates_per(21)
        DesignModel.default_per_page.should eql(21)
      end
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

      it "should create a method for view instance" do
        CouchRest::Model::Designs::View.stub!(:create)
        @object.should_receive(:create_view_method).with('test')
        @object.view('test')
      end

    end

    describe "#create_view_method" do
      before :each do
        @object = @klass.new(DesignModel)
      end

      it "should create a method that returns view instance" do
        CouchRest::Model::Designs::View.should_receive(:new).with(DesignModel, {}, 'test_view').and_return(nil)
        @object.create_view_method('test_view')
        DesignModel.test_view
      end

    end

  end

end
