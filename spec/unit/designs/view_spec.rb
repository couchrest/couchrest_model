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
          expect { @klass.new(String, nil) }.to raise_error(/View cannot be initialized without a parent Model/)
        end
      end

      describe "with CouchRest Model" do

        it "should setup attributes" do
          @obj = @klass.new(@mod.design_doc, @mod, {}, 'test_view')
          expect(@obj.design_doc).to eql(@mod.design_doc)
          expect(@obj.model).to eql(@mod)
          expect(@obj.name).to eql('test_view')
          expect(@obj.query).to be_empty
        end

        it "should complain if there is no name" do
          expect { @klass.new(@mod.design_doc, @mod, {}, nil) }.to raise_error(/Name must be provided/)
        end

      end

      describe "with previous view instance" do

        before :each do
          first = @klass.new(@mod.design_doc, @mod, {}, 'test_view')
          @obj = @klass.new(@mod.design_doc, first, {:foo => :bar})
        end

        it "should copy attributes" do
          expect(@obj.model).to eql(@mod)
          expect(@obj.name).to eql('test_view')
          expect(@obj.query).to eql({:foo => :bar})
        end

        it "should delete query keys if :delete defined" do
          @obj2 = @klass.new(@mod.design_doc, @obj, {:delete => [:foo]})
          expect(@obj2.query).not_to include(:foo)
        end

      end

      describe "with proxy in query for first initialization" do
        it "should set owner to proxy object and remove from query" do
          proxy = double("Proxy")
          @obj = @klass.new(@mod.design_doc, @mod, {:proxy => proxy}, 'test_view')
          expect(@obj.owner).to eql(proxy)
          expect(@obj.model).to eql(@mod)
        end
      end

      describe "with proxy in query for chained instance" do
        it "should set the owner to proxy object instead of parents model" do
          proxy = double("Proxy")
          @obj = @klass.new(@mod.design_doc, @mod, {}, 'test_view')
          expect(@obj.owner).to eql(@mod)
          expect(@obj.model).to eql(@mod)
          @obj = @obj.proxy(proxy)
          expect(@obj.owner).to eql(proxy)
          expect(@obj.model).to eql(@mod)
        end
      end

    end

    describe ".define_and_create" do
      before :each do
        @design_doc = { }
      end

      it "should call define and create_model_methods method" do
        expect(@klass).to receive(:define).with(@design_doc, 'test', {}).and_return(nil)
        expect(@klass).to receive(:create_model_methods).with(@design_doc, 'test', {}).and_return(nil)
        @klass.define_and_create(@design_doc, 'test')
      end

      it "should call define and create_model_methods method with opts" do
        expect(@klass).to receive(:define).with(@design_doc, 'test', {:foo => :bar}).and_return(nil)
        expect(@klass).to receive(:create_model_methods).with(@design_doc, 'test', {:foo => :bar}).and_return(nil)
        @klass.define_and_create(@design_doc, 'test', {:foo => :bar})
      end

    end

    describe ".define" do

      describe "under normal circumstances" do

        before :each do
          @design_doc = { }
          allow(@design_doc).to receive(:model).and_return(DesignViewModel)
        end

        it "should add a basic view" do
          @klass.define(@design_doc, 'test_view', :map => 'foo')
          expect(@design_doc['views']['test_view']).not_to be_nil
        end

        it "should not overwrite reduce if set" do
          @klass.define(@design_doc, 'by_title', :reduce => true)
          expect(@design_doc['views']['by_title']['map']).not_to be_blank
          expect(@design_doc['views']['by_title']['reduce']).to eql(true)
        end

        it "should replace reduce symbol with string name" do
          @klass.define(@design_doc, 'by_title', :reduce => :sum)
          expect(@design_doc['views']['by_title']['map']).not_to be_blank
          expect(@design_doc['views']['by_title']['reduce']).to eql('_sum')
        end

        it "should replace reduce symbol with string if map function present" do
          @klass.define(@design_doc, 'by_title', :map => "function(d) { }", :reduce => :sum)
          expect(@design_doc['views']['by_title']['map']).not_to be_blank
          expect(@design_doc['views']['by_title']['reduce']).to eql('_sum')
        end

        it "should auto generate mapping from name" do
          expect { @klass.define(@design_doc, 'by_title') }.not_to raise_error
          str = @design_doc['views']['by_title']['map']
          expect(str).to include("((doc['#{DesignViewModel.model_type_key}'] == 'DesignViewModel') && (doc['title'] != null))")
          expect(str).to include("emit(doc['title'], 1);")
          str = @design_doc['views']['by_title']['reduce']
          expect(str).to include("_sum")
        end

        it "should auto generate mapping from name with and" do
          @klass.define(@design_doc, 'by_title_and_name')
          str = @design_doc['views']['by_title_and_name']['map']
          expect(str).to include("(doc['title'] != null) && (doc['name'] != null)")
          expect(str).to include("emit([doc['title'], doc['name']], 1);")
          str = @design_doc['views']['by_title_and_name']['reduce']
          expect(str).to include("_sum")
        end

        it "should allow reduce methods as symbols" do
          @klass.define(@design_doc, 'by_title', :reduce => :stats)
          expect(@design_doc['views']['by_title']['reduce']).to eql('_stats')
        end

        it "should allow the emit value to be overridden" do
          @klass.define(@design_doc, 'by_title', :emit => :name)
          str = @design_doc['views']['by_title']['map']
          expect(str).to include("emit(doc['title'], doc['name']);")
        end

        it "should forward a non-symbol emit value straight into the view" do
          @klass.define(@design_doc, 'by_title', :emit => 3)
          str = @design_doc['views']['by_title']['map']
          expect(str).to include("emit(doc['title'], 3);")
        end

        it "should support emitting an array" do
          @klass.define(@design_doc, 'by_title', :emit => [1, :name])
          str = @design_doc['views']['by_title']['map']
          expect(str).to include("emit(doc['title'], [1, doc['name']]);")
        end

        it "should guard against nulls when emitting properties" do
          @klass.define(@design_doc, 'by_title', :emit => :name)
          str = @design_doc['views']['by_title']['map']
          expect(str).to include("doc['name'] != null")
        end

        it "should guard against nulls when emitting multiple properties" do
          @klass.define(@design_doc, 'by_title', :emit => [:name, :another_property])
          str = @design_doc['views']['by_title']['map']
          expect(str).to include("doc['name'] != null")
          expect(str).to include("doc['another_property'] != null")
        end

        it "should not guard against nulls for non-symbol emits" do
          @klass.define(@design_doc, 'by_title', :emit => [:name, 3])
          str = @design_doc['views']['by_title']['map']
          expect(str).not_to include("( != null)")
        end

        it "should not provide a default reduce function the emit value is overridden" do
          @klass.define(@design_doc, 'by_title', :emit => :name)
          str = @design_doc['views']['by_title']['reduce']
          expect(str).to be_nil
        end
      end

      describe ".create_model_methods" do
        before :each do
          @model = DesignViewModel
          @design_doc = { }
          allow(@design_doc).to receive(:model).and_return(@model)
          allow(@design_doc).to receive(:method_name).and_return("design_doc")
          allow(@model).to receive('design_doc').and_return(@design_doc)
        end
        it "should create standard view method" do
          @klass.create_model_methods(@design_doc, 'by_name')
          expect(@model).to respond_to('by_name')
          expect(@design_doc).to receive('view').with('by_name', {})
          @model.by_name
        end
        it "should create find_ view method" do
          @klass.create_model_methods(@design_doc, 'by_name')
          expect(@model).to respond_to('find_by_name')
          view = double("View")
          expect(view).to receive('key').with('fred').and_return(view)
          expect(view).to receive('first').and_return(nil)
          expect(@design_doc).to receive('view').and_return(view)
          @model.find_by_name('fred')
        end
        it "should create find_! view method" do
          @klass.create_model_methods(@design_doc, 'by_name')
          expect(@model).to respond_to('find_by_name!')
          obj = double("SomeKlass")
          view = double("View")
          expect(view).to receive('key').with('fred').and_return(view)
          expect(view).to receive('first').and_return(obj)
          expect(@design_doc).to receive('view').and_return(view)
          expect(@model.find_by_name!('fred')).to eql(obj)
        end
        it "should create find_! view method and raise error when nil" do
          @klass.create_model_methods(@design_doc, 'by_name')
          view = double("View")
          expect(view).to receive('key').with('fred').and_return(view)
          expect(view).to receive('first').and_return(nil)
          expect(@design_doc).to receive('view').and_return(view)
          expect { @model.find_by_name!('fred') }.to raise_error(CouchRest::Model::DocumentNotFound)
        end

      end
    end


    describe "instance methods" do

      before :each do
        @obj = @klass.new(@mod.design_doc, @mod, {}, 'test_view')
      end

      describe "#rows" do
        it "should execute query" do
          expect(@obj).to receive(:execute).and_return(true)
          expect(@obj).to receive(:result).twice.and_return({'rows' => []})
          expect(@obj.rows).to be_empty
        end

        it "should wrap rows in ViewRow class" do
          expect(@obj).to receive(:execute).and_return(true)
          expect(@obj).to receive(:result).twice.and_return({'rows' => [{:foo => :bar}]})
          expect(CouchRest::Model::Designs::ViewRow).to receive(:new).with({:foo => :bar}, @obj.owner)
          @obj.rows
        end

        describe "streaming" do
          let :sample_data do
            [
              {"id" => "doc1", "key" => "doc1", "value" => {"rev" => "4324BB"}},
              {"id" => "doc2", "key" => "doc2", "value" => {"rev" => "2441HF"}},
              {"id" => "doc3", "key" => "doc3", "value" => {"rev" => "74EC24"}}
            ]
          end

          it "should support blocks" do
            expect(@obj).to receive(:execute) do |&block|
              sample_data.each { |r| block.call(r) }
            end
            rows = []
            @obj.rows {|r| rows << r }
            expect(rows.length).to eql(3)
            expect(rows.first).to be_a(CouchRest::Model::Designs::ViewRow)
            expect(rows.first.id).to eql('doc1')
            expect(rows.last.value['rev']).to eql('74EC24')
          end
        end
      end

      describe "#all" do
        it "should ensure docs included and call docs" do
          expect(@obj).to receive(:include_docs!)
          expect(@obj).to receive(:docs)
          @obj.all
        end
        it "should pass on a block" do
          block = lambda { 'ok' }
          expect(@obj).to receive(:docs) { block.call() }
          expect(@obj.all(&block)).to eql('ok')
        end
      end

      describe "#docs" do
        it "should provide docs from rows" do
          expect(@obj).to receive(:rows).and_return([])
          @obj.docs
        end
        it "should cache the results" do
          expect(@obj).to receive(:rows).once.and_return([])
          @obj.docs
          @obj.docs
        end

        describe "streaming" do
          let :sample_data do
            [
              {"id" => "doc1", "key" => "doc1", "doc" => {"_id" => "123", "type" => 'DesignViewModel', 'name' => 'Test1'}},
              {"id" => "doc3", "key" => "doc3", "doc" => {"_id" => "234", "type" => 'DesignViewModel', 'name' => 'Test2'}}
            ]
          end

          it "should support blocks" do
            expect(@obj).to receive(:execute) do |&block|
              sample_data.each { |r| block.call(r) }
            end
            docs = []
            @obj.docs {|d| docs << d }
            expect(docs.length).to eql(2)
            expect(docs.first).to be_a(DesignViewModel)
            expect(docs.first.name).to eql('Test1')
            expect(docs.last.id).to eql('234')
          end
        end
      end

      describe "#first" do
        it "should provide the first result of loaded query" do
          expect(@obj).to receive(:result).and_return(true)
          expect(@obj).to receive(:all).and_return([:foo])
          expect(@obj.first).to eql(:foo)
        end
        it "should perform a query if no results cached" do
          view = double('SubView')
          expect(@obj).to receive(:result).and_return(nil)
          expect(@obj).to receive(:limit).with(1).and_return(view)
          expect(view).to receive(:all).and_return([:foo])
          expect(@obj.first).to eql(:foo)
        end
      end

      describe "#last" do
        it "should provide the last result of loaded query" do
          expect(@obj).to receive(:result).and_return(true)
          expect(@obj).to receive(:all).and_return([:foo, :bar])
          expect(@obj.first).to eql(:foo)
        end
        it "should perform a query if no results cached" do
          view = double('SubView')
          expect(@obj).to receive(:result).and_return(nil)
          expect(@obj).to receive(:limit).with(1).and_return(view)
          expect(view).to receive(:descending).and_return(view)
          expect(view).to receive(:all).and_return([:foo, :bar])
          expect(@obj.last).to eql(:bar)
        end
      end

      describe "#length" do
        it "should provide a length from the docs array" do
          expect(@obj).to receive(:docs).and_return([1, 2, 3])
          expect(@obj.length).to eql(3)
        end
      end

      describe "#count" do
        it "should raise an error if view prepared for group" do
          expect(@obj).to receive(:query).and_return({:group => true})
          expect { @obj.count }.to raise_error(/group/)
        end

        it "should return first row value if reduce possible" do
          view = double("SubView")
          row = double("Row")
          expect(@obj).to receive(:can_reduce?).and_return(true)
          expect(@obj).to receive(:reduce).and_return(view)
          expect(view).to receive(:skip).with(0).and_return(view)
          expect(view).to receive(:limit).with(1).and_return(view)
          expect(view).to receive(:rows).and_return([row])
          expect(row).to receive(:value).and_return(2)
          expect(@obj.count).to eql(2)
        end
        it "should return 0 if no rows and reduce possible" do
          view = double("SubView")
          expect(@obj).to receive(:can_reduce?).and_return(true)
          expect(@obj).to receive(:reduce).and_return(view)
          expect(view).to receive(:skip).with(0).and_return(view)
          expect(view).to receive(:limit).with(1).and_return(view)
          expect(view).to receive(:rows).and_return([])
          expect(@obj.count).to eql(0)
        end

        it "should perform limit request for total_rows" do
          view = double("SubView")
          expect(@obj).to receive(:limit).with(0).and_return(view)
          expect(view).to receive(:total_rows).and_return(4)
          expect(@obj).to receive(:can_reduce?).and_return(false)
          expect(@obj.count).to eql(4)
        end
      end

      describe "#empty?" do
        it "should check the #all method for any results" do
          all = double("All")
          expect(all).to receive(:empty?).and_return('win')
          expect(@obj).to receive(:all).and_return(all)
          expect(@obj.empty?).to eql('win')
        end
      end

      describe "#each" do
        it "should call each method on all" do
          expect(@obj).to receive(:all).and_return([])
          @obj.each
        end
        it "should call each and pass block" do
          set = [:foo, :bar]
          expect(@obj).to receive(:all).and_return(set)
          result = []
          @obj.each do |s|
            result << s
          end
          expect(result).to eql(set)
        end
      end

      describe "#offset" do
        it "should excute" do
          expect(@obj).to receive(:execute).and_return({'offset' => 3})
          expect(@obj.offset).to eql(3)
        end
      end

      describe "#total_rows" do
        it "should excute" do
          expect(@obj).to receive(:execute).and_return({'total_rows' => 3})
          expect(@obj.total_rows).to eql(3)
        end
      end

      describe "#values" do
        it "should request each row and provide value" do
          row = double("Row")
          expect(row).to receive(:value).twice.and_return('foo')
          expect(@obj).to receive(:rows).and_return([row, row])
          expect(@obj.values).to eql(['foo', 'foo'])
        end
      end

      describe "#[]" do
        it "should execute and provide requested field" do
          expect(@obj).to receive(:execute).and_return({'total_rows' => 2})
          expect(@obj['total_rows']).to eql(2)
        end
      end

      describe "#info" do
        it "should raise error" do
          expect { @obj.info }.to raise_error(/Not yet implemented/)
        end
      end

      describe "#key" do
        it "should update query with value" do
          expect(@obj).to receive(:update_query).with({:key => 'foo'})
          @obj.key('foo')
        end
        it "should raise error if startkey set" do
          @obj.query[:startkey] = 'bar'
          expect { @obj.key('foo') }.to raise_error(/View#key cannot be used/)
        end
        it "should raise error if endkey set" do
          @obj.query[:endkey] = 'bar'
          expect { @obj.key('foo') }.to raise_error(/View#key cannot be used/)
        end
        it "should raise error if both startkey and endkey set" do
          @obj.query[:startkey] = 'bar'
          @obj.query[:endkey] = 'bar'
          expect { @obj.key('foo') }.to raise_error(/View#key cannot be used/)
        end
        it "should raise error if keys set" do
          @obj.query[:keys] = 'bar'
          expect { @obj.key('foo') }.to raise_error(/View#key cannot be used/)
        end
      end

      describe "#startkey" do
        it "should update query with value" do
          expect(@obj).to receive(:update_query).with({:startkey => 'foo'})
          @obj.startkey('foo')
        end
        it "should raise and error if key set" do
          @obj.query[:key] = 'bar'
          expect { @obj.startkey('foo') }.to raise_error(/View#startkey/)
        end
        it "should raise and error if keys set" do
          @obj.query[:keys] = 'bar'
          expect { @obj.startkey('foo') }.to raise_error(/View#startkey/)
        end
      end

      describe "#startkey_doc" do
        it "should update query with value" do
          expect(@obj).to receive(:update_query).with({:startkey_docid => 'foo'})
          @obj.startkey_doc('foo')
        end
        it "should update query with object id if available" do
          doc = double("Document")
          expect(doc).to receive(:id).and_return(44)
          expect(@obj).to receive(:update_query).with({:startkey_docid => 44})
          @obj.startkey_doc(doc)
        end
      end

      describe "#endkey" do
        it "should update query with value" do
          expect(@obj).to receive(:update_query).with({:endkey => 'foo'})
          @obj.endkey('foo')
        end
        it "should raise and error if key set" do
          @obj.query[:key] = 'bar'
          expect { @obj.endkey('foo') }.to raise_error(/View#endkey/)
        end
        it "should raise and error if keys set" do
          @obj.query[:keys] = 'bar'
          expect { @obj.endkey('foo') }.to raise_error(/View#endkey/)
        end
      end

      describe "#endkey_doc" do
        it "should update query with value" do
          expect(@obj).to receive(:update_query).with({:endkey_docid => 'foo'})
          @obj.endkey_doc('foo')
        end
        it "should update query with object id if available" do
          doc = double("Document")
          expect(doc).to receive(:id).and_return(44)
          expect(@obj).to receive(:update_query).with({:endkey_docid => 44})
          @obj.endkey_doc(doc)
        end
      end

      describe "#keys" do
        it "should update the query" do
          expect(@obj).to receive(:update_query).with({:keys => ['foo', 'bar']})
          @obj.keys(['foo', 'bar'])
        end
        it "should raise and error if key set" do
          @obj.query[:key] = 'bar'
          expect { @obj.keys('foo') }.to raise_error(/View#keys/)
        end
        it "should raise and error if startkey or endkey set" do
          @obj.query[:startkey] = 'bar'
          expect { @obj.keys('foo') }.to raise_error(/View#keys/)
          @obj.query.delete(:startkey)
          @obj.query[:endkey] = 'bar'
          expect { @obj.keys('foo') }.to raise_error(/View#keys/)
        end
      end

      describe "#keys (without parameters)" do
        it "should request each row and provide key value" do
          row = double("Row")
          expect(row).to receive(:key).twice.and_return('foo')
          expect(@obj).to receive(:rows).and_return([row, row])
          expect(@obj.keys).to eql(['foo', 'foo'])
        end
      end

      describe "#descending" do
        it "should update query" do
          expect(@obj).to receive(:update_query).with({:descending => true})
          @obj.descending
        end
        it "should reverse start and end keys if given" do
          @obj = @obj.startkey('a').endkey('z')
          @obj = @obj.descending
          expect(@obj.query[:endkey]).to eql('a')
          expect(@obj.query[:startkey]).to eql('z')
        end
        it "should reverse even if start or end nil" do
          @obj = @obj.startkey('a')
          @obj = @obj.descending
          expect(@obj.query[:endkey]).to eql('a')
          expect(@obj.query[:startkey]).to be_nil
        end
        it "should reverse start_doc and end_doc keys if given" do
          @obj = @obj.startkey_doc('a').endkey_doc('z')
          @obj = @obj.descending
          expect(@obj.query[:endkey_docid]).to eql('a')
          expect(@obj.query[:startkey_docid]).to eql('z')
        end
      end

      describe "#limit" do
        it "should update query with value" do
          expect(@obj).to receive(:update_query).with({:limit => 3})
          @obj.limit(3)
        end
      end

      describe "#skip" do
        it "should update query with value" do
          expect(@obj).to receive(:update_query).with({:skip => 3})
          @obj.skip(3)
        end
        it "should update query with default value" do
          expect(@obj).to receive(:update_query).with({:skip => 0})
          @obj.skip
        end
      end

      describe "#reduce" do
        it "should update query" do
          expect(@obj).to receive(:can_reduce?).and_return(true)
          expect(@obj).to receive(:update_query).with({:reduce => true, :delete => [:include_docs]})
          @obj.reduce
        end
        it "should raise error if query cannot be reduced" do
          expect(@obj).to receive(:can_reduce?).and_return(false)
          expect { @obj.reduce }.to raise_error(/Cannot reduce a view without a reduce method/)
        end
      end

      describe "#group" do
        it "should update query" do
          expect(@obj).to receive(:query).and_return({:reduce => true})
          expect(@obj).to receive(:update_query).with({:group => true})
          @obj.group
        end
        it "should raise error if query not prepared for reduce" do
          expect(@obj).to receive(:query).and_return({:reduce => false})
          expect { @obj.group }.to raise_error(/View#reduce must have been set before grouping is permitted/)
        end
      end

      describe "#group" do
        it "should update query" do
          expect(@obj).to receive(:query).and_return({:reduce => true})
          expect(@obj).to receive(:update_query).with({:group => true})
          @obj.group
        end
        it "should raise error if query not prepared for reduce" do
          expect(@obj).to receive(:query).and_return({:reduce => false})
          expect { @obj.group }.to raise_error(/View#reduce must have been set before grouping is permitted/)
        end
      end

      describe "#group_level" do
        it "should update query" do
          expect(@obj).to receive(:group).and_return(@obj)
          expect(@obj).to receive(:update_query).with({:group_level => 3})
          @obj.group_level(3)
        end
      end

      describe "#stale" do
        it "should update query with ok" do
          expect(@obj).to receive(:update_query).with(:stale => 'ok')
          @obj.stale('ok')
        end
        it "should update query with update_after" do
          expect(@obj).to receive(:update_query).with(:stale => 'update_after')
          @obj.stale('update_after')
        end
        it "should fail if anything else is provided" do
          expect { @obj.stale('yes') }.to raise_error(/can only be set with/)
        end
      end

      describe "#include_docs" do
        it "should call include_docs! on new view" do
          expect(@obj).to receive(:update_query).and_return(@obj)
          expect(@obj).to receive(:include_docs!)
          @obj.include_docs
        end
      end

      describe "#reset!" do
        it "should empty all cached data" do
          expect(@obj).to receive(:result=).with(nil)
          @obj.instance_exec { @rows = 'foo'; @docs = 'foo' }
          @obj.reset!
          expect(@obj.instance_exec { @rows }).to be_nil
          expect(@obj.instance_exec { @docs }).to be_nil
        end
      end

      #### PROTECTED METHODS

      describe "#include_docs!" do
        it "should set query value" do
          expect(@obj).to receive(:result).and_return(false)
          expect(@obj).not_to receive(:reset!)
          @obj.send(:include_docs!)
          expect(@obj.query[:include_docs]).to be_truthy
        end
        it "should reset if result and no docs" do
          expect(@obj).to receive(:result).and_return(true)
          expect(@obj).to receive(:include_docs?).and_return(false)
          expect(@obj).to receive(:reset!)
          @obj.send(:include_docs!)
          expect(@obj.query[:include_docs]).to be_truthy
        end
        it "should raise an error if view is reduced" do
          @obj.query[:reduce] = true
          expect { @obj.send(:include_docs!) }.to raise_error(/Cannot include documents in view that has been reduced/)
        end
      end

      describe "#include_docs?" do
        it "should return true if set" do
          expect(@obj).to receive(:query).and_return({:include_docs => true})
          expect(@obj.send(:include_docs?)).to be_truthy
        end
        it "should return false if not set" do
          expect(@obj).to receive(:query).and_return({})
          expect(@obj.send(:include_docs?)).to be_falsey
          expect(@obj).to receive(:query).and_return({:include_docs => false})
          expect(@obj.send(:include_docs?)).to be_falsey
        end
      end

      describe "#update_query" do
        it "returns a new instance of view" do
          expect(@obj.send(:update_query).object_id).not_to eql(@obj.object_id)
        end

        it "returns a new instance of view with extra parameters" do
          new_obj = @obj.send(:update_query, {:foo => :bar})
          expect(new_obj.query[:foo]).to eql(:bar)
        end
      end

      describe "#can_reduce?" do
        it "should check and prove true" do
          expect(@obj).to receive(:name).and_return('test_view')
          expect(@obj).to receive(:design_doc).and_return({'views' => {'test_view' => {'reduce' => 'foo'}}})
          expect(@obj.send(:can_reduce?)).to be_truthy
        end
        it "should check and prove false" do
          expect(@obj).to receive(:name).and_return('test_view')
          expect(@obj).to receive(:design_doc).and_return({'views' => {'test_view' => {'reduce' => nil}}})
          expect(@obj.send(:can_reduce?)).to be_falsey
        end
      end

      describe "#execute" do
        before :each do
          # disable real execution!
          @design_doc = double("DesignDoc")
          allow(@design_doc).to receive(:view_on)
          allow(@design_doc).to receive(:sync)
          allow(@obj).to receive(:design_doc).and_return(@design_doc)
        end

        it "should return previous result if set" do
          @obj.result = "foo"
          expect(@obj.send(:execute)).to eql('foo')
        end

        it "should raise issue if no database" do
          expect(@obj).to receive(:database).and_return(nil)
          expect { @obj.send(:execute) }.to raise_error(CouchRest::Model::DatabaseNotDefined)
        end

        it "should delete the reduce option if not going to be used" do
          expect(@obj).to receive(:can_reduce?).and_return(false)
          expect(@obj.query).to receive(:delete).with(:reduce)
          @obj.send(:execute)
        end

        it "should call to save the design document" do
          expect(@obj).to receive(:can_reduce?).and_return(false)
          expect(@design_doc).to receive(:sync).with(DB)
          @obj.send(:execute)
        end

        it "should populate the results" do
          expect(@obj).to receive(:can_reduce?).and_return(true)
          expect(@design_doc).to receive(:view_on).and_return('foos')
          @obj.send(:execute)
          expect(@obj.result).to eql('foos')
        end

        it "should not remove nil values from query" do
          expect(@obj).to receive(:can_reduce?).and_return(true)
          allow(@obj).to receive(:use_database).and_return(@mod.database)
          @obj.query = {:reduce => true, :limit => nil, :skip => nil}
          expect(@design_doc).to receive(:view_on).with(@mod.database, 'test_view', {:reduce => true, :limit => nil, :skip => nil})
          @obj.send(:execute)
        end

        it "should accept a block and pass to view_on" do
          row = {'id' => '1234'}
          expect(@design_doc).to receive(:view_on) { |db,n,q,&block| block.call(row) }
          expect(@obj).to receive(:can_reduce?).and_return(true)
          @obj.send(:execute) do |r|
            expect(r).to eql(row)
          end
        end

      end

      describe "pagination methods" do

        describe "#page" do
          it "should call limit and skip" do
            expect(@obj).to receive(:limit).with(25).and_return(@obj)
            expect(@obj).to receive(:skip).with(25).and_return(@obj)
            @obj.page(2)
          end
        end

        describe "#per" do
          it "should raise an error if page not called before hand" do
            expect { @obj.per(12) }.to raise_error(/View#page must be called before #per/)
          end
          it "should not do anything if number less than or eql 0" do
            view = @obj.page(1)
            expect(view.per(0)).to eql(view)
          end
          it "should set limit and update skip" do
            view = @obj.page(2).per(10)
            expect(view.query[:skip]).to eql(10)
            expect(view.query[:limit]).to eql(10)
          end
        end

        describe "#total_count" do
          it "set limit and skip to nill and perform count" do
            expect(@obj).to receive(:limit).with(nil).and_return(@obj)
            expect(@obj).to receive(:skip).with(nil).and_return(@obj)
            expect(@obj).to receive(:count).and_return(5)
            expect(@obj.total_count).to eql(5)
            expect(@obj.total_count).to eql(5) # Second to test caching
          end
        end

        describe "#total_pages" do
          it "should use total_count and limit_value" do
            expect(@obj).to receive(:total_count).and_return(200)
            expect(@obj).to receive(:limit_value).and_return(25)
            expect(@obj.total_pages).to eql(8)
          end
        end

        # `num_pages` aliases to `total_pages` for compatibility for Kaminari '< 0.14'
        describe "#num_pages" do
          it "should use total_count and limit_value" do
            expect(@obj).to receive(:total_count).and_return(200)
            expect(@obj).to receive(:limit_value).and_return(25)
            expect(@obj.num_pages).to eql(8)
          end
        end

        describe "#current_page" do
          it "should use offset and limit" do
            expect(@obj).to receive(:offset_value).and_return(25)
            expect(@obj).to receive(:limit_value).and_return(25)
            expect(@obj.current_page).to eql(2)
          end
        end
      end

      describe "ActiveRecord compatibility methods" do
        describe "#model_name" do
          it "should use the #model class" do
            expect(@obj.model_name.to_s).to eql DesignViewModel.to_s
          end
        end
      end
    end
  end

  describe "ViewRow" do

    before :all do
      @klass = CouchRest::Model::Designs::ViewRow
    end

    let :owner do
      m = double()
      allow(m).to receive(:database).and_return(DB)
      m
    end

    describe "intialize" do
      it "should store reference to owner" do
        obj = @klass.new({}, owner)
        expect(obj.owner).to eql(owner)
      end
      it "should copy details from hash" do
        obj = @klass.new({:foo => :bar, :test => :example}, owner)
        expect(obj[:foo]).to eql(:bar)
        expect(obj[:test]).to eql(:example)
      end
    end

    describe "running" do
      before :each do
      end

      it "should provide id" do
        obj = @klass.new({'id' => '123456'}, owner)
        expect(obj.id).to eql('123456')
      end

      it "should provide key" do
        obj = @klass.new({'key' => 'thekey'}, owner)
        expect(obj.key).to eql('thekey')
      end

      it "should provide the value" do
        obj = @klass.new({'value' => 'thevalue'}, owner)
        expect(obj.value).to eql('thevalue')
      end

      it "should provide the raw document" do
        obj = @klass.new({'doc' => 'thedoc'}, owner)
        expect(obj.raw_doc).to eql('thedoc')
      end

      it "should instantiate a new document" do
        hash = {'doc' => {'_id' => '12345', 'name' => 'sam'}}
        obj = @klass.new(hash, DesignViewModel)
        doc = double('DesignViewDoc')
        expect(obj.owner).to receive(:build_from_database).with(hash['doc']).and_return(doc)
        expect(obj.doc).to eql(doc)
      end

      it "should try to load from id if no document" do
        hash = {'id' => '12345', 'value' => 5}
        obj = @klass.new(hash, DesignViewModel)
        doc = double('DesignViewModel')
        expect(obj.owner).to receive(:get).with('12345').and_return(doc)
        expect(obj.doc).to eql(doc)
      end

      it "should try to load linked document if available" do
        hash = {'id' => '12345', 'value' => {'_id' => '54321'}}
        obj = @klass.new(hash, DesignViewModel)
        doc = double('DesignViewModel')
        expect(obj.owner).to receive(:get).with('54321').and_return(doc)
        expect(obj.doc).to eql(doc)
      end

      it "should try to return nil for document if none available" do
        hash = {'value' => 23} # simulate reduce
        obj = @klass.new(hash, DesignViewModel)
        expect(obj.owner).not_to receive(:get)
        expect(obj.doc).to be_nil
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
        expect(DesignViewModel.by_name.first.name).to eql("Judith")
      end

      it "should return last" do
        expect(DesignViewModel.by_name.last.name).to eql("Vilma")
      end

      it "should allow multiple results" do
        view = DesignViewModel.by_name.limit(3)
        expect(view.total_rows).to eql(5)
        expect(view.last.name).to eql("Peter")
        expect(view.all.length).to eql(3)
      end

      it "should not return document if nil key provided" do
        expect(DesignViewModel.by_name.key(nil).first).to be_nil
      end
    end

    describe "index information" do
      it "should provide total_rows" do
        expect(DesignViewModel.by_name.total_rows).to eql(5)
      end
      it "should provide total_rows" do
        expect(DesignViewModel.by_name.total_rows).to eql(5)
      end
      it "should provide an offset" do
        expect(DesignViewModel.by_name.offset).to eql(0)
      end
      it "should provide a set of keys" do
        expect(DesignViewModel.by_name.limit(2).keys).to eql(["Judith", "Lorena"])
      end
    end

    describe "viewing" do
      it "should load views with no reduce method" do
        docs = DesignViewModel.by_just_name.all
        expect(docs.length).to eql(5)
      end
      it "should load documents by specific keys" do
        docs = DesignViewModel.by_name.keys(["Judith", "Peter"]).all
        expect(docs[0].name).to eql("Judith")
        expect(docs[1].name).to eql("Peter")
      end
      it "should provide count even if limit or skip set" do
        docs = DesignViewModel.by_name.limit(20).skip(2)
        expect(docs.count).to eql(5)
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
        expect(@view.total_pages).to eql(2)
      end
      it "should return results from first page" do
        expect(@view.all.first.name).to eql('Judith')
        expect(@view.all.last.name).to eql('Peter')
      end
      it "should return results from second page" do
        expect(@view.page(2).all.first.name).to eql('Sam')
        expect(@view.page(2).all.last.name).to eql('Vilma')
      end

      it "should allow overriding per page count" do
        @view = @view.per(10)
        expect(@view.total_pages).to eql(1)
        expect(@view.all.last.name).to eql('Vilma')
      end
    end

    describe "concurrent view accesses" do

      # NOTE: must use `DesignViewModel2` instead of `DesignViewModel` to mimic
      # a "cold" start of a multi-threaded application (as the checksum is
      # stored at the class level)
      class DesignViewModel2 < CouchRest::Model::Base
        use_database DB
        property :name

        design do
          view :by_name
        end
      end

      it "should not conflict" do
        expect {
          threads = 2.times.map {
            Thread.new {
              DesignViewModel2.by_name.page(1).to_a
            }
          }
          threads.each(&:join)
        }.to_not raise_error
      end

    end

  end


end
