require "spec_helper"

class DesignModel < CouchRest::Model::Base
end

describe CouchRest::Model::Designs do

  it "should accessable from model" do
    DesignModel.respond_to?(:design).should be_true
  end

  describe "class methods" do

    describe ".design" do

      before :each do
        @klass = DesignModel.dup
      end

      describe "without block" do
        it "should create design_doc and all methods" do
          @klass.design
          @klass.should respond_to(:design_doc)
          @klass.should respond_to(:all)
        end

        it "should created named design_doc method and not all" do
          @klass.design :stats
          @klass.should respond_to(:stats_design_doc)
          @klass.should_not respond_to(:all)
        end
      end

      describe "with block" do
        it "should pass calls to mapper" do
          @klass.design do
            disable_auto_update
          end
          @klass.design_doc.auto_update.should be_false
        end
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

    describe 'initialize with prefix' do

      before :all do
        @object = @klass.new(DesignModel)
      end

      it "should set basic variables" do
        @object.send(:model).should eql(DesignModel)
        @object.send(:prefix).should be_nil
        @object.send(:method).should eql('design_doc')
      end

      it "should create an all method" do
        @object.model.should respond_to('all')
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

      it "should not create an all method" do
        @object.model.should respond_to('all')
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
        CouchRest::Model::Designs::View.should_receive(:create).with(DesignModel, @object.design_doc, 'test', {})
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

    describe "#create_view_method" do
      before :each do
        @object = @klass.new(DesignModel)
      end

      it "should create a method that returns view instance" do
        @object.design_doc.should_receive(:view).with({}, 'test_view').and_return(nil)
        @object.send(:create_view_method, 'test_view')
        DesignModel.test_view
      end

      it "should create a method that returns quick access find_by method" do
        view = mock("View")
        view.stub(:key).and_return(view)
        view.stub(:first).and_return(true)
        @object.design_doc.should_receive(:view).with({}, 'by_test_view').and_return(view)
        @object.send(:create_view_method, 'by_test_view')
        lambda { DesignModel.find_by_test_view('test').should be_true }.should_not raise_error
      end

    end

  end

end
