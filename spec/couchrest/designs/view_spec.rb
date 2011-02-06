require File.expand_path("../../../spec_helper", __FILE__)

class DesignViewModel < CouchRest::Model::Base
  use_database DB
  property :name
  property :title

  design do
    view :by_name
  end
end

describe "Design View" do

  before :each do
    @klass = CouchRest::Model::Designs::View
  end

  describe ".new" do

    describe "with invalid parent model" do
      it "should burn" do
        lambda { @klass.new(String) }.should raise_exception
      end
    end

    describe "with CouchRest Model" do

      it "should setup attributes" do
        @obj = @klass.new(DesignViewModel, {}, 'test_view')
        @obj.model.should eql(DesignViewModel)
        @obj.name.should eql('test_view')
        @obj.query.should eql({:reduce => false})
      end

      it "should complain if there is no name" do
        lambda { @klass.new(DesignViewModel, {}, nil) }.should raise_error
      end

    end

    describe "with previous view instance" do

      before :each do
        first = @klass.new(DesignViewModel, {}, 'test_view')
        @obj = @klass.new(first, {:foo => :bar})
      end

      it "should copy attributes" do
        @obj.model.should eql(DesignViewModel)
        @obj.name.should eql('test_view')
        @obj.query.should eql({:reduce => false, :foo => :bar})
      end

    end

  end

  describe ".create" do

    before :each do
      @design_doc = {}
      DesignViewModel.stub!(:design_doc).and_return(@design_doc)
    end

    it "should add a basic view" do
      @klass.create(DesignViewModel, 'test_view', :map => 'foo')
      @design_doc['views']['test_view'].should_not be_nil
    end

    it "should auto generate mapping from name" do
      lambda { @klass.create(DesignViewModel, 'by_title') }.should_not raise_error
      str = @design_doc['views']['by_title']['map']
      str.should include("((doc['couchrest-type'] == 'DesignViewModel') && (doc['title'] != null))")
      str.should include("emit(doc['title'], null);")
    end

    it "should auto generate mapping from name with and" do
      @klass.create(DesignViewModel, 'by_title_and_name')
      str = @design_doc['views']['by_title_and_name']['map']
      str.should include("(doc['title'] != null) && (doc['name'] != null)")
      str.should include("emit([doc['title'], doc['name']], null);")
    end

  end

  describe "instance methods" do

    before :each do
      @obj = @klass.new(DesignViewModel, {}, 'test_view')
    end

    describe "#update_query" do
      it "returns a new instance of view" do
        @obj.send(:update_query).object_id.should_not eql(@obj.object_id)
      end

      it "returns a new instance of view with extra parameters" do
        new_obj = @obj.send(:update_query, {:foo => :bar})
        new_obj.query[:foo].should eql(:bar)
      end

    end

  end
  
  ##############

  describe "with real data" do

    before :all do
      @objs = [
        {:name => "Sam"},
        {:name => "Lorena"},
        {:name => "Peter"},
        {:name => "Judith"},
        {:name => "Vilma"}
      ].map{|h| DesignViewModel.create(h)}
    end

    describe "just documents" do

      it "should return all" do
        DesignViewModel.by_name.all.last.name.should eql("Vilma")
      end

    end

    describe "index information" do
      it "should provide total_rows" do
        DesignViewModel.by_name.total_rows.should eql(5)
      end
      it "should provide total_rows" do
        DesignViewModel.by_name.total_rows.should eql(5)
      end
      it "should provide an offset" do
        DesignViewModel.by_name.offset.should eql(0)
      end
      it "should provide a set of keys" do
        DesignViewModel.by_name.limit(2).keys.should eql(["Judith", "Lorena"])
      end

    end

  end


end
