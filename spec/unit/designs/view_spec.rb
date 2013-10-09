require File.expand_path("../../../spec_helper", __FILE__)

class DesignViewModel < CouchRest::Model::Base
  use_database DB
  property :name
  property :title

  design do
    view :by_name
    view :by_just_name, :map => "function(doc) { emit(doc['name'], null); }"
  end
end

describe "Design View" do

  describe "(unit tests)" do

    before :each do
      @mod   = DesignViewModel
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
          @obj = @klass.new(@mod.design_doc, @mod, {}, 'test_view')
          @obj.design_doc.should eql(@mod.design_doc)
          @obj.model.should eql(@mod)
          @obj.name.should eql('test_view')
          @obj.query.should be_empty
        end

        it "should complain if there is no name" do
          lambda { @klass.new(@mod.design_doc, @mod, {}, nil) }.should raise_error(/Name must be provided/)
        end

      end

      describe "with previous view instance" do

        before :each do
          first = @klass.new(@mod.design_doc, @mod, {}, 'test_view')
          @obj = @klass.new(@mod.design_doc, first, {:foo => :bar})
        end

        it "should copy attributes" do
          @obj.model.should eql(@mod)
          @obj.name.should eql('test_view')
          @obj.query.should eql({:foo => :bar})
        end

        it "should delete query keys if :delete defined" do
          @obj2 = @klass.new(@mod.design_doc, @obj, {:delete => [:foo]})
          @obj2.query.should_not include(:foo)
        end

      end

      describe "with proxy in query for first initialization" do
        it "should set model to proxy object and remove from query" do
          proxy = mock("Proxy")
          @obj = @klass.new(@mod.design_doc, @mod, {:proxy => proxy}, 'test_view')
          @obj.model.should eql(proxy)
        end
      end

      describe "with proxy in query for chained instance" do
        it "should set the model to proxy object instead of parents model" do
          proxy = mock("Proxy")
          @obj = @klass.new(@mod.design_doc, @mod, {}, 'test_view')
          @obj.model.should eql(@mod)
          @obj = @obj.proxy(proxy)
          @obj.model.should eql(proxy)
        end
      end

    end

    describe ".define_and_create" do
      before :each do
        @design_doc = { }
      end

      it "should call define and create_model_methods method" do
        @klass.should_receive(:define).with(@design_doc, 'test', {}).and_return(nil)
        @klass.should_receive(:create_model_methods).with(@design_doc, 'test', {}).and_return(nil)
        @klass.define_and_create(@design_doc, 'test')
      end

      it "should call define and create_model_methods method with opts" do
        @klass.should_receive(:define).with(@design_doc, 'test', {:foo => :bar}).and_return(nil)
        @klass.should_receive(:create_model_methods).with(@design_doc, 'test', {:foo => :bar}).and_return(nil)
        @klass.define_and_create(@design_doc, 'test', {:foo => :bar})
      end

    end

    describe ".define" do

      describe "under normal circumstances" do

        before :each do
          @design_doc = { }
          @design_doc.stub!(:model).and_return(DesignViewModel)
        end

        it "should add a basic view" do
          @klass.define(@design_doc, 'test_view', :map => 'foo')
          @design_doc['views']['test_view'].should_not be_nil
        end

        it "should not overwrite reduce if set" do
          @klass.define(@design_doc, 'by_title', :reduce => true)
          @design_doc['views']['by_title']['map'].should_not be_blank
          @design_doc['views']['by_title']['reduce'].should eql(true)
        end

        it "should replace reduce symbol with string name" do
          @klass.define(@design_doc, 'by_title', :reduce => :sum)
          @design_doc['views']['by_title']['map'].should_not be_blank
          @design_doc['views']['by_title']['reduce'].should eql('_sum')
        end

        it "should replace reduce symbol with string if map function present" do
          @klass.define(@design_doc, 'by_title', :map => "function(d) { }", :reduce => :sum)
          @design_doc['views']['by_title']['map'].should_not be_blank
          @design_doc['views']['by_title']['reduce'].should eql('_sum')
        end

        it "should auto generate mapping from name" do
          lambda { @klass.define(@design_doc, 'by_title') }.should_not raise_error
          str = @design_doc['views']['by_title']['map']
          str.should include("((doc['#{DesignViewModel.model_type_key}'] == 'DesignViewModel') && (doc['title'] != null))")
          str.should include("emit(doc['title'], 1);")
          str = @design_doc['views']['by_title']['reduce']
          str.should include("_sum")
        end

        it "should auto generate mapping from name with and" do
          @klass.define(@design_doc, 'by_title_and_name')
          str = @design_doc['views']['by_title_and_name']['map']
          str.should include("(doc['title'] != null) && (doc['name'] != null)")
          str.should include("emit([doc['title'], doc['name']], 1);")
          str = @design_doc['views']['by_title_and_name']['reduce']
          str.should include("_sum")
        end

        it "should allow reduce methods as symbols" do
          @klass.define(@design_doc, 'by_title', :reduce => :stats)
          @design_doc['views']['by_title']['reduce'].should eql('_stats')
        end
      end

      describe ".create_model_methods" do
        before :each do
          @model = DesignViewModel
          @design_doc = { }
          @design_doc.stub!(:model).and_return(@model)
          @design_doc.stub!(:method_name).and_return("design_doc")
          @model.stub!('design_doc').and_return(@design_doc)
        end
        it "should create standard view method" do
          @klass.create_model_methods(@design_doc, 'by_name')
          @model.should respond_to('by_name')
          @design_doc.should_receive('view').with('by_name', {})
          @model.by_name
        end
        it "should create find_ view method" do
          @klass.create_model_methods(@design_doc, 'by_name')
          @model.should respond_to('find_by_name')
          view = mock("View")
          view.should_receive('key').with('fred').and_return(view)
          view.should_receive('first').and_return(nil)
          @design_doc.should_receive('view').and_return(view)
          @model.find_by_name('fred')
        end
      end
    end


    describe "instance methods" do

      before :each do
        @obj = @klass.new(@mod.design_doc, @mod, {}, 'test_view')
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

      describe "#length" do
        it "should provide a length from the docs array" do
          @obj.should_receive(:docs).and_return([1, 2, 3])
          @obj.length.should eql(3)
        end
      end

      describe "#count" do
        it "should raise an error if view prepared for group" do
          @obj.should_receive(:query).and_return({:group => true})
          lambda { @obj.count }.should raise_error(/group/)
        end

        it "should return first row value if reduce possible" do
          view = mock("SubView")
          row = mock("Row")
          @obj.should_receive(:can_reduce?).and_return(true)
          @obj.should_receive(:reduce).and_return(view)
          view.should_receive(:skip).with(0).and_return(view)
          view.should_receive(:limit).with(1).and_return(view)
          view.should_receive(:rows).and_return([row])
          row.should_receive(:value).and_return(2)
          @obj.count.should eql(2)
        end
        it "should return 0 if no rows and reduce possible" do
          view = mock("SubView")
          @obj.should_receive(:can_reduce?).and_return(true)
          @obj.should_receive(:reduce).and_return(view)
          view.should_receive(:skip).with(0).and_return(view)
          view.should_receive(:limit).with(1).and_return(view)
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

      describe "#empty?" do
        it "should check the #all method for any results" do
          all = mock("All")
          all.should_receive(:empty?).and_return('win')
          @obj.should_receive(:all).and_return(all)
          @obj.empty?.should eql('win')
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

      describe "#values" do
        it "should request each row and provide value" do
          row = mock("Row")
          row.should_receive(:value).twice.and_return('foo')
          @obj.should_receive(:rows).and_return([row, row])
          @obj.values.should eql(['foo', 'foo'])
        end
      end

      describe "#[]" do
        it "should execute and provide requested field" do
          @obj.should_receive(:execute).and_return({'total_rows' => 2})
          @obj['total_rows'].should eql(2)
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
        it "should raise error if startkey set" do
          @obj.query[:startkey] = 'bar'
          lambda { @obj.key('foo') }.should raise_error
        end
        it "should raise error if endkey set" do
          @obj.query[:endkey] = 'bar'
          lambda { @obj.key('foo') }.should raise_error
        end
        it "should raise error if both startkey and endkey set" do
          @obj.query[:startkey] = 'bar'
          @obj.query[:endkey] = 'bar'
          lambda { @obj.key('foo') }.should raise_error
        end
        it "should raise error if keys set" do
          @obj.query[:keys] = 'bar'
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
          lambda { @obj.startkey('foo') }.should raise_error(/View#startkey/)
        end
        it "should raise and error if keys set" do
          @obj.query[:keys] = 'bar'
          lambda { @obj.startkey('foo') }.should raise_error(/View#startkey/)
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
          lambda { @obj.endkey('foo') }.should raise_error(/View#endkey/)
        end
        it "should raise and error if keys set" do
          @obj.query[:keys] = 'bar'
          lambda { @obj.endkey('foo') }.should raise_error(/View#endkey/)
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

      describe "#keys" do
        it "should update the query" do
          @obj.should_receive(:update_query).with({:keys => ['foo', 'bar']})
          @obj.keys(['foo', 'bar'])
        end
        it "should raise and error if key set" do
          @obj.query[:key] = 'bar'
          lambda { @obj.keys('foo') }.should raise_error(/View#keys/)
        end
        it "should raise and error if startkey or endkey set" do
          @obj.query[:startkey] = 'bar'
          lambda { @obj.keys('foo') }.should raise_error(/View#keys/)
          @obj.query.delete(:startkey)
          @obj.query[:endkey] = 'bar'
          lambda { @obj.keys('foo') }.should raise_error(/View#keys/)
        end
      end

      describe "#keys (without parameters)" do
        it "should request each row and provide key value" do
          row = mock("Row")
          row.should_receive(:key).twice.and_return('foo')
          @obj.should_receive(:rows).and_return([row, row])
          @obj.keys.should eql(['foo', 'foo'])
        end
      end

      describe "#descending" do
        it "should update query" do
          @obj.should_receive(:update_query).with({:descending => true})
          @obj.descending
        end
        it "should reverse start and end keys if given" do
          @obj = @obj.startkey('a').endkey('z')
          @obj = @obj.descending
          @obj.query[:endkey].should eql('a')
          @obj.query[:startkey].should eql('z')
        end
        it "should reverse even if start or end nil" do
          @obj = @obj.startkey('a')
          @obj = @obj.descending
          @obj.query[:endkey].should eql('a')
          @obj.query[:startkey].should be_nil
        end
        it "should reverse start_doc and end_doc keys if given" do
          @obj = @obj.startkey_doc('a').endkey_doc('z')
          @obj = @obj.descending
          @obj.query[:endkey_docid].should eql('a')
          @obj.query[:startkey_docid].should eql('z')
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
          @obj.should_receive(:update_query).with({:reduce => true, :delete => [:include_docs]})
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

      describe "#stale" do
        it "should update query with ok" do
          @obj.should_receive(:update_query).with(:stale => 'ok')
          @obj.stale('ok')
        end
        it "should update query with update_after" do
          @obj.should_receive(:update_query).with(:stale => 'update_after')
          @obj.stale('update_after')
        end
        it "should fail if anything else is provided" do
          lambda { @obj.stale('yes') }.should raise_error(/can only be set with/)
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
        it "should raise an error if view is reduced" do
          @obj.query[:reduce] = true
          lambda { @obj.send(:include_docs!) }.should raise_error
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
          @design_doc.stub!(:sync)
          @obj.stub!(:design_doc).and_return(@design_doc)
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

        it "should call to save the design document" do
          @obj.should_receive(:can_reduce?).and_return(false)
          @design_doc.should_receive(:sync).with(DB)
          @obj.send(:execute)
        end

        it "should populate the results" do
          @obj.should_receive(:can_reduce?).and_return(true)
          @design_doc.should_receive(:view_on).and_return('foos')
          @obj.send(:execute)
          @obj.result.should eql('foos')
        end

        it "should not remove nil values from query" do
          @obj.should_receive(:can_reduce?).and_return(true)
          @obj.stub!(:use_database).and_return(@mod.database)
          @obj.query = {:reduce => true, :limit => nil, :skip => nil}
          @design_doc.should_receive(:view_on).with(@mod.database, 'test_view', {:reduce => true, :limit => nil, :skip => nil})
          @obj.send(:execute)
        end


      end

      describe "pagination methods" do

        describe "#page" do
          it "should call limit and skip" do
            @obj.should_receive(:limit).with(25).and_return(@obj)
            @obj.should_receive(:skip).with(25).and_return(@obj)
            @obj.page(2)
          end
        end

        describe "#per" do
          it "should raise an error if page not called before hand" do
            lambda { @obj.per(12) }.should raise_error
          end
          it "should not do anything if number less than or eql 0" do
            view = @obj.page(1)
            view.per(0).should eql(view)
          end
          it "should set limit and update skip" do
            view = @obj.page(2).per(10)
            view.query[:skip].should eql(10)
            view.query[:limit].should eql(10)
          end
        end

        describe "#total_count" do
          it "set limit and skip to nill and perform count" do
            @obj.should_receive(:limit).with(nil).and_return(@obj)
            @obj.should_receive(:skip).with(nil).and_return(@obj)
            @obj.should_receive(:count).and_return(5)
            @obj.total_count.should eql(5)
            @obj.total_count.should eql(5) # Second to test caching
          end
        end

        describe "#total_pages" do
          it "should use total_count and limit_value" do
            @obj.should_receive(:total_count).and_return(200)
            @obj.should_receive(:limit_value).and_return(25)
            @obj.total_pages.should eql(8)
          end
        end

        # `num_pages` aliases to `total_pages` for compatibility for Kaminari '< 0.14'
        describe "#num_pages" do
          it "should use total_count and limit_value" do
            @obj.should_receive(:total_count).and_return(200)
            @obj.should_receive(:limit_value).and_return(25)
            @obj.num_pages.should eql(8)
          end
        end

        describe "#current_page" do
          it "should use offset and limit" do
            @obj.should_receive(:offset_value).and_return(25)
            @obj.should_receive(:limit_value).and_return(25)
            @obj.current_page.should eql(2)
          end
        end
      end
    end
  end

  describe "ViewRow" do

    before :all do
      @klass = CouchRest::Model::Designs::ViewRow
    end

    describe "intialize" do
      it "should store reference to model" do
        obj = @klass.new({}, "model")
        obj.model.should eql('model')
      end
      it "should copy details from hash" do
        obj = @klass.new({:foo => :bar, :test => :example}, "")
        obj[:foo].should eql(:bar)
        obj[:test].should eql(:example)
      end
    end

    describe "running" do
      before :each do
      end

      it "should provide id" do
        obj = @klass.new({'id' => '123456'}, 'model')
        obj.id.should eql('123456')
      end

      it "should provide key" do
        obj = @klass.new({'key' => 'thekey'}, 'model')
        obj.key.should eql('thekey')
      end

      it "should provide the value" do
        obj = @klass.new({'value' => 'thevalue'}, 'model')
        obj.value.should eql('thevalue')
      end

      it "should provide the raw document" do
        obj = @klass.new({'doc' => 'thedoc'}, 'model')
        obj.raw_doc.should eql('thedoc')
      end

      it "should instantiate a new document" do
        hash = {'doc' => {'_id' => '12345', 'name' => 'sam'}}
        obj = @klass.new(hash, DesignViewModel)
        doc = mock('DesignViewModel')
        obj.model.should_receive(:build_from_database).with(hash['doc']).and_return(doc)
        obj.doc.should eql(doc)
      end

      it "should try to load from id if no document" do
        hash = {'id' => '12345', 'value' => 5}
        obj = @klass.new(hash, DesignViewModel)
        doc = mock('DesignViewModel')
        obj.model.should_receive(:get).with('12345').and_return(doc)
        obj.doc.should eql(doc)
      end

      it "should try to load linked document if available" do
        hash = {'id' => '12345', 'value' => {'_id' => '54321'}}
        obj = @klass.new(hash, DesignViewModel)
        doc = mock('DesignViewModel')
        obj.model.should_receive(:get).with('54321').and_return(doc)
        obj.doc.should eql(doc)
      end

      it "should try to return nil for document if none available" do
        hash = {'value' => 23} # simulate reduce
        obj = @klass.new(hash, DesignViewModel)
        doc = mock('DesignViewModel')
        obj.model.should_not_receive(:get)
        obj.doc.should be_nil
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

      it "should not return document if nil key provided" do
        DesignViewModel.by_name.key(nil).first.should be_nil
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

    describe "viewing" do
      it "should load views with no reduce method" do
        docs = DesignViewModel.by_just_name.all
        docs.length.should eql(5)
      end
      it "should load documents by specific keys" do
        docs = DesignViewModel.by_name.keys(["Judith", "Peter"]).all
        docs[0].name.should eql("Judith")
        docs[1].name.should eql("Peter")
      end
      it "should provide count even if limit or skip set" do
        docs = DesignViewModel.by_name.limit(20).skip(2)
        docs.count.should eql(5)
      end
    end

    describe "pagination" do
      before :all do
        DesignViewModel.paginates_per 3
      end
      before :each do
        @view = DesignViewModel.by_name.page(1)
      end

      it "should calculate number of pages" do
        @view.total_pages.should eql(2)
      end
      it "should return results from first page" do
        @view.all.first.name.should eql('Judith')
        @view.all.last.name.should eql('Peter')
      end
      it "should return results from second page" do
        @view.page(2).all.first.name.should eql('Sam')
        @view.page(2).all.last.name.should eql('Vilma')
      end

      it "should allow overriding per page count" do
        @view = @view.per(10)
        @view.total_pages.should eql(1)
        @view.all.last.name.should eql('Vilma')
      end
    end

  end


end
