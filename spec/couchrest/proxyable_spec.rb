require File.expand_path("../../spec_helper", __FILE__)

require File.join(FIXTURE_PATH, 'more', 'cat')

class DummyProxyable < CouchRest::Model::Base
  def proxy_database
    'db' # Do not use this!
  end
end

class ProxyKitten < CouchRest::Model::Base
end

describe "Proxyable" do

  it "should provide #model_proxy method" do
    DummyProxyable.new.should respond_to(:model_proxy)
  end

  describe "class methods" do

    describe ".proxy_for" do

      it "should be provided" do
        DummyProxyable.should respond_to(:proxy_for)
      end

      it "should create a new method" do
        DummyProxyable.stub!(:method_defined?).and_return(true)
        DummyProxyable.proxy_for(:cats)
        DummyProxyable.new.should respond_to(:cats)
      end

      describe "generated method" do
        it "should call ModelProxy" do
          DummyProxyable.proxy_for(:cats)
          @obj = DummyProxyable.new
          CouchRest::Model::Proxyable::ModelProxy.should_receive(:new).with(Cat, @obj, 'dummy_proxyable', 'db').and_return(true)
          @obj.should_receive('proxy_database').and_return('db')
          @obj.should_receive(:respond_to?).with('proxy_database').and_return(true)
          @obj.cats
        end

        it "should call class on root namespace" do
          class ::Document < CouchRest::Model::Base
            def self.foo; puts 'bar'; end
          end
          DummyProxyable.proxy_for(:documents)
          @obj = DummyProxyable.new
          CouchRest::Model::Proxyable::ModelProxy.should_receive(:new).with(::Document, @obj, 'dummy_proxyable', 'db').and_return(true)
          @obj.should_receive('proxy_database').and_return('db')
          @obj.should_receive(:respond_to?).with('proxy_database').and_return(true)
          @obj.documents
        end

        it "should raise an error if the database method is missing" do
          DummyProxyable.proxy_for(:cats)
          @obj = DummyProxyable.new
          @obj.should_receive(:respond_to?).with('proxy_database').and_return(false)
          lambda { @obj.cats }.should raise_error(StandardError, "Missing #proxy_database method for proxy")
        end

        it "should raise an error if custom database method missing" do
          DummyProxyable.proxy_for(:proxy_kittens, :database_method => "foobardom")
          @obj = DummyProxyable.new
          lambda { @obj.proxy_kittens }.should raise_error(StandardError, "Missing #foobardom method for proxy")
        end


      end

    end

    describe ".proxied_by" do
      it "should be provided" do
        DummyProxyable.should respond_to(:proxied_by)
      end

      it "should add an attribute accessor" do
        DummyProxyable.proxied_by(:foobar)
        DummyProxyable.new.should respond_to(:foobar)
      end

      it "should raise an error if model name pre-defined" do
        lambda { DummyProxyable.proxied_by(:object_id) }.should raise_error
      end
    end

  end

  describe "ModelProxy" do
    
    before :all do
      @klass = CouchRest::Model::Proxyable::ModelProxy
    end

    it "should initialize and set variables" do
      @obj = @klass.new(Cat, 'owner', 'owner_name', 'database')
      @obj.model.should eql(Cat)
      @obj.owner.should eql('owner')
      @obj.owner_name.should eql('owner_name')
      @obj.database.should eql('database')
    end

    describe "instance" do

      before :each do
        @obj = @klass.new(Cat, 'owner', 'owner_name', 'database')
      end

      it "should proxy new call" do
        Cat.should_receive(:new).and_return({})
        @obj.should_receive(:proxy_update).and_return(true)
        @obj.new
      end

      it "should proxy build_from_database" do
        Cat.should_receive(:build_from_database).and_return({})
        @obj.should_receive(:proxy_update).with({}).and_return(true)
        @obj.build_from_database
      end

      describe "#method_missing" do
        it "should return design view object" do
          m = "by_some_property"
          inst = mock('DesignView')
          inst.stub!(:proxy).and_return(inst)
          @obj.should_receive(:has_view?).with(m).and_return(true)
          Cat.should_receive(:respond_to?).with(m).and_return(true)
          Cat.should_receive(:send).with(m).and_return(inst)
          @obj.method_missing(m).should eql(inst)
        end

        it "should call view if necessary" do
          m = "by_some_property"
          @obj.should_receive(:has_view?).with(m).and_return(true)
          Cat.should_receive(:respond_to?).with(m).and_return(false)
          @obj.should_receive(:view).with(m, {}).and_return('view')
          @obj.method_missing(m).should eql('view')
        end

        it "should provide wrapper for #first_from_view" do
          m = "find_by_some_property"
          view = "by_some_property"
          @obj.should_receive(:has_view?).with(m).and_return(false)
          @obj.should_receive(:has_view?).with(view).and_return(true)
          @obj.should_receive(:first_from_view).with(view).and_return('view')
          @obj.method_missing(m).should eql('view')    
        end

      end

      it "should proxy #all" do
        Cat.should_receive(:all).with({:database => 'database'})
        @obj.should_receive(:proxy_update_all)
        @obj.all
      end
  
      it "should proxy #count" do
        Cat.should_receive(:all).with({:database => 'database', :raw => true, :limit => 0}).and_return({'total_rows' => 3})
        @obj.count.should eql(3)
      end

      it "should proxy #first" do
        Cat.should_receive(:first).with({:database => 'database'})
        @obj.should_receive(:proxy_update)
        @obj.first
      end

      it "should proxy #last" do
        Cat.should_receive(:last).with({:database => 'database'})
        @obj.should_receive(:proxy_update)
        @obj.last
      end

      it "should proxy #get" do
        Cat.should_receive(:get).with(32, 'database')
        @obj.should_receive(:proxy_update)
        @obj.get(32)
      end
      it "should proxy #find" do
        Cat.should_receive(:get).with(32, 'database')
        @obj.should_receive(:proxy_update)
        @obj.find(32)
      end

      it "should proxy #has_view?" do
        Cat.should_receive(:has_view?).with('view').and_return(false)
        @obj.has_view?('view')
      end

      it "should proxy #view_by" do
        Cat.should_receive(:view_by).with('name').and_return(false)
        @obj.view_by('name')
      end

      it "should proxy #view" do
        Cat.should_receive(:view).with('view', {:database => 'database'})
        @obj.should_receive(:proxy_update_all)
        @obj.view('view')
      end

      it "should proxy #first_from_view" do
        Cat.should_receive(:first_from_view).with('view', {:database => 'database'})
        @obj.should_receive(:proxy_update)
        @obj.first_from_view('view')
      end

      it "should proxy design_doc" do
        Cat.should_receive(:design_doc)
        @obj.design_doc
      end

      describe "#refresh_design_doc" do
        it "should be proxied without database arg" do
          Cat.should_receive(:refresh_design_doc).with('database')
          @obj.refresh_design_doc
        end
        it "should be proxied with database arg" do
          Cat.should_receive(:refresh_design_doc).with('db')
          @obj.refresh_design_doc('db')
        end
      end

      describe "#save_design_doc" do
        it "should be proxied without args" do
          Cat.should_receive(:save_design_doc).with('database')
          @obj.save_design_doc
        end

        it "should be proxied with database arg" do
          Cat.should_receive(:save_design_doc).with('db')
          @obj.save_design_doc('db')
        end
      end

      

      ### Updating methods

      describe "#proxy_update" do
        it "should set returned doc fields" do
          doc = mock(:Document)
          doc.should_receive(:respond_to?).with(:database=).and_return(true)
          doc.should_receive(:database=).with('database')
          doc.should_receive(:respond_to?).with(:model_proxy=).and_return(true)
          doc.should_receive(:model_proxy=).with(@obj)
          doc.should_receive(:respond_to?).with('owner_name=').and_return(true)
          doc.should_receive(:send).with('owner_name=', 'owner')
          @obj.send(:proxy_update, doc).should eql(doc)
        end

        it "should not fail if some fields missing" do
          doc = mock(:Document)
          doc.should_receive(:respond_to?).with(:database=).and_return(true)
          doc.should_receive(:database=).with('database')
          doc.should_receive(:respond_to?).with(:model_proxy=).and_return(false)
          doc.should_not_receive(:model_proxy=)
          doc.should_receive(:respond_to?).with('owner_name=').and_return(false)
          doc.should_not_receive(:owner_name=)
          @obj.send(:proxy_update, doc).should eql(doc)
        end

        it "should pass nil straight through without errors" do
          lambda { @obj.send(:proxy_update, nil).should eql(nil) }.should_not raise_error
        end
      end

      it "#proxy_update_all should update array of docs" do
        docs = [{}, {}]
        @obj.should_receive(:proxy_update).twice.with({})
        @obj.send(:proxy_update_all, docs)
      end

    end

  end

  describe "scenarios" do

    before :all do
      class ProxyableCompany < CouchRest::Model::Base
        use_database DB
        property :slug
        proxy_for :proxyable_invoices
        def proxy_database
          @db ||= TEST_SERVER.database!(TESTDB + "-#{slug}")
        end
      end

      class ProxyableInvoice < CouchRest::Model::Base
        property :client
        property :total
        proxied_by :proxyable_company
        validates_uniqueness_of :client
        design do
          view :by_total
        end
      end


      @company = ProxyableCompany.create(:slug => 'samco')
    end

    it "should create the new database" do
      @company.proxyable_invoices.all.should be_empty
      TEST_SERVER.databases.find{|db| db =~ /#{TESTDB}-samco/}.should_not be_nil
    end

    it "should allow creation of new entries" do
      inv = @company.proxyable_invoices.new(:client => "Lorena", :total => 35)
      inv.save.should be_true
      @company.proxyable_invoices.count.should eql(1)
      @company.proxyable_invoices.first.client.should eql("Lorena")
    end

    it "should validate uniqueness" do
      inv = @company.proxyable_invoices.new(:client => "Lorena", :total => 40)
      inv.save.should be_false
    end

    it "should allow design views" do
      item = @company.proxyable_invoices.by_total.key(35).first
      item.client.should eql('Lorena')
    end

  end

end
