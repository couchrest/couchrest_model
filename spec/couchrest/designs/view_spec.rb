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

  describe "(unit tests)" do

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
        str.should include("emit(doc['title'], 1);")
        str = @design_doc['views']['by_title']['reduce']
        str.should include("return sum(values);")
      end

      it "should auto generate mapping from name with and" do
        @klass.create(DesignViewModel, 'by_title_and_name')
        str = @design_doc['views']['by_title_and_name']['map']
        str.should include("(doc['title'] != null) && (doc['name'] != null)")
        str.should include("emit([doc['title'], doc['name']], 1);")
        str = @design_doc['views']['by_title_and_name']['reduce']
        str.should include("return sum(values);")
      end

    end

    describe "instance methods" do

      before :each do
        @obj = @klass.new(DesignViewModel, {}, 'test_view')
      end

      describe "#rows" do
        it "should execute query" do
          @obj.should_receive(:execute).and_return(true)
          @obj.should_receive(:result).twice.and_return({'rows' => []})
          @obj.rows.should be_empty
        end

        it "should wrap rows in ViewRow class" do
          @obj.should_receive(:execute).and_return(true)
          @obj.should_receive(:result).twice.and_return({'rows' => [{:foo => :bar}]})
          CouchRest::Model::Designs::ViewRow.should_receive(:new).with({:foo => :bar}, @obj.model)
          @obj.rows
        end
      end

      describe "#all" do
        it "should ensure docs included and call docs" do
          @obj.should_receive(:include_docs!)
          @obj.should_receive(:docs)
          @obj.all
        end
      end

      describe "#docs" do
        it "should provide docs from rows" do
          @obj.should_receive(:rows).and_return([])
          @obj.docs
        end
        it "should cache the results" do
          @obj.should_receive(:rows).once.and_return([])
          @obj.docs
          @obj.docs
        end
      end

      describe "#first" do
        it "should provide the first result of loaded query" do
          @obj.should_receive(:result).and_return(true)
          @obj.should_receive(:all).and_return([:foo])
          @obj.first.should eql(:foo)
        end
        it "should perform a query if no results cached" do
          view = mock('SubView')
          @obj.should_receive(:result).and_return(nil)
          @obj.should_receive(:limit).with(1).and_return(view)
          view.should_receive(:all).and_return([:foo])
          @obj.first.should eql(:foo)
        end
      end

      describe "#last" do
        it "should provide the last result of loaded query" do
          @obj.should_receive(:result).and_return(true)
          @obj.should_receive(:all).and_return([:foo, :bar])
          @obj.first.should eql(:foo)
        end
        it "should perform a query if no results cached" do
          view = mock('SubView')
          @obj.should_receive(:result).and_return(nil)
          @obj.should_receive(:limit).with(1).and_return(view)
          view.should_receive(:descending).and_return(view)
          view.should_receive(:all).and_return([:foo, :bar])
          @obj.last.should eql(:bar)
        end
      end

      describe "#count" do
        it "should raise an error if view prepared for group" do
          @obj.should_receive(:query).and_return({:group => true})
          lambda { @obj.count }.should raise_error
        end

        it "should return first row value if reduce possible" do
          view = mock("SubView")
          row = mock("Row")
          @obj.should_receive(:can_reduce?).and_return(true)
          @obj.should_receive(:reduce).and_return(view)
          view.should_receive(:rows).and_return([row])
          row.should_receive(:value).and_return(2)
          @obj.count.should eql(2)
        end
        it "should return 0 if no rows and reduce possible" do
          view = mock("SubView")
          @obj.should_receive(:can_reduce?).and_return(true)
          @obj.should_receive(:reduce).and_return(view)
          view.should_receive(:rows).and_return([])
          @obj.count.should eql(0)
        end

        it "should perform limit request for total_rows" do
          view = mock("SubView")
          @obj.should_receive(:limit).with(0).and_return(view)
          view.should_receive(:total_rows).and_return(4)
          @obj.should_receive(:can_reduce?).and_return(false)
          @obj.count.should eql(4)
        end
      end

      describe "#each" do
        it "should call each method on all" do
          @obj.should_receive(:all).and_return([])
          @obj.each
        end
        it "should call each and pass block" do
          set = [:foo, :bar]
          @obj.should_receive(:all).and_return(set)
          result = []
          @obj.each do |s|
            result << s
          end
          result.should eql(set)
        end
      end

      describe "#offset" do
        it "should excute" do
          @obj.should_receive(:execute).and_return({'offset' => 3})
          @obj.offset.should eql(3)
        end
      end

      describe "#total_rows" do
        it "should excute" do
          @obj.should_receive(:execute).and_return({'total_rows' => 3})
          @obj.total_rows.should eql(3)
        end
      end

      describe "#keys" do
        it "should request each row and provide key value" do
          row = mock("Row")
          row.should_receive(:key).twice.and_return('foo')
          @obj.should_receive(:rows).and_return([row, row])
          @obj.keys.should eql(['foo', 'foo'])
        end
      end

      describe "#values" do
        it "should request each row and provide value" do
          row = mock("Row")
          row.should_receive(:value).twice.and_return('foo')
          @obj.should_receive(:rows).and_return([row, row])
          @obj.values.should eql(['foo', 'foo'])
        end
      end

      describe "#info" do
        it "should raise error" do
          lambda { @obj.info }.should raise_error
        end
      end

      describe "#database" do
        it "should update query with value" do
          @obj.should_receive(:update_query).with({:database => 'foo'})
          @obj.database('foo')
        end
      end

      describe "#key" do
        it "should update query with value" do
          @obj.should_receive(:update_query).with({:key => 'foo'})
          @obj.key('foo')
        end
        it "should raise and error if startkey set" do
          @obj.query[:startkey] = 'bar'
          lambda { @obj.key('foo') }.should raise_error
        end
        it "should raise and error if endkey set" do
          @obj.query[:endkey] = 'bar'
          lambda { @obj.key('foo') }.should raise_error
        end
        it "should raise and error if both startkey and endkey set" do
          @obj.query[:startkey] = 'bar'
          @obj.query[:endkey] = 'bar'
          lambda { @obj.key('foo') }.should raise_error
        end
      end
      
      describe "#startkey" do
        it "should update query with value" do
          @obj.should_receive(:update_query).with({:startkey => 'foo'})
          @obj.startkey('foo')
        end
        it "should raise and error if key set" do
          @obj.query[:key] = 'bar'
          lambda { @obj.startkey('foo') }.should raise_error
        end
      end

      describe "#startkey_doc" do
        it "should update query with value" do
          @obj.should_receive(:update_query).with({:startkey_docid => 'foo'})
          @obj.startkey_doc('foo')
        end
        it "should update query with object id if available" do
          doc = mock("Document")
          doc.should_receive(:id).and_return(44)
          @obj.should_receive(:update_query).with({:startkey_docid => 44})
          @obj.startkey_doc(doc)
        end
      end

      describe "#endkey" do
        it "should update query with value" do
          @obj.should_receive(:update_query).with({:endkey => 'foo'})
          @obj.endkey('foo')
        end
        it "should raise and error if key set" do
          @obj.query[:key] = 'bar'
          lambda { @obj.endkey('foo') }.should raise_error
        end
      end

      describe "#endkey_doc" do
        it "should update query with value" do
          @obj.should_receive(:update_query).with({:endkey_docid => 'foo'})
          @obj.endkey_doc('foo')
        end
        it "should update query with object id if available" do
          doc = mock("Document")
          doc.should_receive(:id).and_return(44)
          @obj.should_receive(:update_query).with({:endkey_docid => 44})
          @obj.endkey_doc(doc)
        end
      end

      describe "#descending" do
        it "should update query" do
          @obj.should_receive(:update_query).with({:descending => true})
          @obj.descending
        end
      end

      describe "#limit" do
        it "should update query with value" do
          @obj.should_receive(:update_query).with({:limit => 3})
          @obj.limit(3)
        end
      end

      describe "#skip" do
        it "should update query with value" do 
          @obj.should_receive(:update_query).with({:skip => 3})
          @obj.skip(3)
        end
        it "should update query with default value" do 
          @obj.should_receive(:update_query).with({:skip => 0})
          @obj.skip
        end
      end

      describe "#reduce" do
        it "should update query" do
          @obj.should_receive(:can_reduce?).and_return(true)
          @obj.should_receive(:update_query).with({:reduce => true})
          @obj.reduce
        end
        it "should raise error if query cannot be reduced" do
          @obj.should_receive(:can_reduce?).and_return(false)
          lambda { @obj.reduce }.should raise_error
        end
      end

      describe "#group" do
        it "should update query" do
          @obj.should_receive(:query).and_return({:reduce => true})
          @obj.should_receive(:update_query).with({:group => true})
          @obj.group
        end
        it "should raise error if query not prepared for reduce" do
          @obj.should_receive(:query).and_return({:reduce => false})
          lambda { @obj.group }.should raise_error
        end
      end

      describe "#group" do
        it "should update query" do
          @obj.should_receive(:query).and_return({:reduce => true})
          @obj.should_receive(:update_query).with({:group => true})
          @obj.group
        end
        it "should raise error if query not prepared for reduce" do
          @obj.should_receive(:query).and_return({:reduce => false})
          lambda { @obj.group }.should raise_error
        end
      end

      describe "#group_level" do
        it "should update query" do
          @obj.should_receive(:group).and_return(@obj)
          @obj.should_receive(:update_query).with({:group_level => 3})
          @obj.group_level(3)
        end
      end

      describe "#include_docs" do
        it "should call include_docs! on new view" do
          @obj.should_receive(:update_query).and_return(@obj)
          @obj.should_receive(:include_docs!)
          @obj.include_docs
        end
      end

      describe "#reset!" do
        it "should empty all cached data" do
          @obj.should_receive(:result=).with(nil)
          @obj.instance_exec { @rows = 'foo'; @docs = 'foo' }
          @obj.reset!
          @obj.instance_exec { @rows }.should be_nil
          @obj.instance_exec { @docs }.should be_nil
        end
      end

      #### PROTECTED METHODS

      describe "#include_docs!" do
        it "should set query value" do
          @obj.should_receive(:result).and_return(false)
          @obj.should_not_receive(:reset!)
          @obj.send(:include_docs!)
          @obj.query[:include_docs].should be_true
        end
        it "should reset if result and no docs" do
          @obj.should_receive(:result).and_return(true)
          @obj.should_receive(:include_docs?).and_return(false)
          @obj.should_receive(:reset!)
          @obj.send(:include_docs!)
          @obj.query[:include_docs].should be_true
        end
      end

      describe "#include_docs?" do
        it "should return true if set" do
          @obj.should_receive(:query).and_return({:include_docs => true})
          @obj.send(:include_docs?).should be_true
        end
        it "should return false if not set" do
          @obj.should_receive(:query).and_return({})
          @obj.send(:include_docs?).should be_false
          @obj.should_receive(:query).and_return({:include_docs => false})
          @obj.send(:include_docs?).should be_false
        end
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

      describe "#design_doc" do
        it "should call design_doc on model" do
          @obj.model.should_receive(:design_doc)
          @obj.send(:design_doc)
        end
      end

      describe "#can_reduce?" do
        it "should check and prove true" do
          @obj.should_receive(:name).and_return('test_view')
          @obj.should_receive(:design_doc).and_return({'views' => {'test_view' => {'reduce' => 'foo'}}})
          @obj.send(:can_reduce?).should be_true
        end
        it "should check and prove false" do
          @obj.should_receive(:name).and_return('test_view')
          @obj.should_receive(:design_doc).and_return({'views' => {'test_view' => {'reduce' => nil}}})
          @obj.send(:can_reduce?).should be_false
        end
      end

      describe "#execute" do
        before :each do
          # disable real execution!
          @design_doc = mock("DesignDoc")
          @design_doc.stub!(:view_on)
          @obj.model.stub!(:design_doc).and_return(@design_doc)
        end

        it "should return previous result if set" do
          @obj.result = "foo"
          @obj.send(:execute).should eql('foo')
        end

        it "should raise issue if no database" do
          @obj.should_receive(:query).and_return({:database => nil})
          model = mock("SomeModel")
          model.should_receive(:database).and_return(nil)
          @obj.should_receive(:model).and_return(model)
          lambda { @obj.send(:execute) }.should raise_error
        end

        it "should delete the reduce option if not going to be used" do
          @obj.should_receive(:can_reduce?).and_return(false)
          @obj.query.should_receive(:delete).with(:reduce)
          @obj.send(:execute)
        end

        it "should populate the results" do
          @obj.should_receive(:can_reduce?).and_return(true)
          @design_doc.should_receive(:view_on).and_return('foos')
          @obj.send(:execute)
          @obj.result.should eql('foos')
        end

        it "should retry once on a resource not found error" do
          @obj.should_receive(:can_reduce?).and_return(true)
          @obj.model.should_receive(:save_design_doc)
          @design_doc.should_receive(:view_on).ordered
            .and_raise(RestClient::ResourceNotFound)
          @design_doc.should_receive(:view_on).ordered
            .and_return('foos')
          @obj.send(:execute)
          @obj.result.should eql('foos')
        end

        it "should retry twice and fail on a resource not found error" do
          @obj.should_receive(:can_reduce?).and_return(true)
          @obj.model.should_receive(:save_design_doc)
          @design_doc.should_receive(:view_on).twice
            .and_raise(RestClient::ResourceNotFound)
          lambda { @obj.send(:execute) }.should raise_error(RestClient::ResourceNotFound)
        end


      end

    end
  end
  

  describe "scenarios" do

    before :all do
      @objs = [
        {:name => "Judith"},
        {:name => "Lorena"},
        {:name => "Peter"},
        {:name => "Sam"},
        {:name => "Vilma"}
      ].map{|h| DesignViewModel.create(h)}
    end

    describe "loading documents" do

      it "should return first" do
        DesignViewModel.by_name.first.name.should eql("Judith")
      end

      it "should return last" do
        DesignViewModel.by_name.last.name.should eql("Vilma")
      end

      it "should allow multiple results" do
        view = DesignViewModel.by_name.limit(3)
        view.total_rows.should eql(5)
        view.last.name.should eql("Peter")
        view.all.length.should eql(3)
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
