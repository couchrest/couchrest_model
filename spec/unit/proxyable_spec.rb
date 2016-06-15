require "spec_helper"

class DummyProxyable < CouchRest::Model::Base
  proxy_database_method :db
  def db
    'db'
  end
end

class ProxyKitten < CouchRest::Model::Base
end

describe CouchRest::Model::Proxyable do

  describe "#proxy_database" do

    before do
      @class = Class.new(CouchRest::Model::Base)
      @class.class_eval do 
        def slug; 'proxy'; end
      end
      @obj = @class.new
    end

    it "should respond to method" do
      @obj.should respond_to(:proxy_database)
    end

    it "should provide proxy database from method" do
      expect(@class).to receive(:proxy_database_method).at_least(:twice).and_return(:slug)
      expect(@obj.proxy_database(:assoc)).to be_a(CouchRest::Database)
      expect(@obj.proxy_database(:assoc).name).to eql('couchrest_proxy')
    end

    it "should raise an error if called and no proxy_database_method set" do
      lambda { @obj.proxy_database(:assoc) }.should raise_error(StandardError, /Please set/)
    end

    it "should support passing a suffix" do
      @class.stub(:proxy_database_method).and_return(:slug)
      @class.stub(:proxy_database_suffixes).and_return({ assoc: 'suffix' })
      lambda { @obj.proxy_database(:assoc) }.should_not raise_error
    end

    it "should join the suffix to the database name" do
      @class.stub(:proxy_database_method).and_return(:slug)
      @class.stub(:proxy_database_suffixes).and_return({ assoc: 'suffix' })
      expect(@obj.proxy_database(:assoc).name).to eql('couchrest_proxy_suffix')
    end

    it "should support multiple databases" do
      @class.stub(:proxy_database_method).and_return(:slug)
      @class.stub(:proxy_database_suffixes).and_return({ assoc: 'suffix', another_assoc: "another_suffix" })
      expect(@obj.proxy_database(:assoc).name).to eql('couchrest_proxy_suffix')
      expect(@obj.proxy_database(:another_assoc).name).to eql('couchrest_proxy_another_suffix')
    end

    it "should use the configuration's join character to add the suffix" do
      @class.connection.update(:join => '-')
      @class.stub(:proxy_database_method).and_return(:slug)
      @class.stub(:proxy_database_suffixes).and_return({ assoc: 'suffix' })
      expect(@obj.proxy_database(:assoc).name).to eql('couchrest-proxy-suffix')
    end
  end

  describe "class methods" do


    describe ".proxy_owner_method" do
      before(:each) do
        @class = DummyProxyable.clone
      end
      it "should provide proxy_owner_method accessors" do
        @class.should respond_to(:proxy_owner_method)
        @class.should respond_to(:proxy_owner_method=)
      end
      it "should work as expected" do
        @class.proxy_owner_method = "foo"
        @class.proxy_owner_method.should eql("foo")
      end
    end

    describe ".proxy_database_method" do
      before do
        @class = Class.new(CouchRest::Model::Base)
      end
      it "should be possible to set the proxy database method" do
        @class.proxy_database_method :db
        @class.proxy_database_method.should eql(:db)
      end
    end

    describe ".proxy_for" do
      before(:each) do
        @class = DummyProxyable.clone
      end

      it "should be provided" do
        @class.should respond_to(:proxy_for)
      end

      it "should add model name to proxied model name array" do
        @class.proxy_for(:cats)
        @class.proxied_model_names.should eql(['Cat'])
      end

      it "should add method names to proxied method name array" do
        @class.proxy_for(:cats)
        @class.proxy_method_names.should eql([:cats])
      end

      it "should accept a class_name override" do
        @class.proxy_for(:felines, class_name: "Cat")
        @class.proxy_method_names.should eql([:felines])
        @class.proxied_model_names.should eql(['Cat'])
      end

      describe "proxy database suffix" do
        it "should support not passing a suffix" do
          @class.proxy_for(:cats)
          @class.proxy_database_suffixes.should eql({ cats: nil })
        end

        it "should set the database suffix if provided" do
          @class.proxy_for(:cats, use_suffix: true)
          @class.proxy_database_suffixes.should eql({ cats: 'cats' })
        end

        it "should accept a database suffix override" do
          @class.proxy_for(:cats, database_suffix: 'felines')
          @class.proxy_database_suffixes.should eql({ cats: 'felines' })
        end
      end

      it "should create a new method" do
        DummyProxyable.stub(:method_defined?).and_return(true)
        DummyProxyable.proxy_for(:cats)
        DummyProxyable.new.should respond_to(:cats)
      end

      describe "generated method" do
        it "should call ModelProxy" do
          DummyProxyable.proxy_for(:cats)
          @obj = DummyProxyable.new
          CouchRest::Model::Proxyable::ModelProxy.should_receive(:new).with(Cat, @obj, 'dummy_proxyable', 'db').and_return(true)
          @obj.should_receive(:proxy_database).and_return('db')
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
          @obj.documents
        end
      end
    end

    describe ".proxied_by" do
      before do
        @class = Class.new(CouchRest::Model::Base)
      end

      it "should be provided" do
        @class.should respond_to(:proxied_by)
      end

      it "should add an attribute accessor" do
        @class.proxied_by(:foobar)
        @class.new.should respond_to(:foobar)
      end

      it "should provide #model_proxy method" do
        @class.proxied_by(:foobar)
        @class.new.should respond_to(:model_proxy)
      end

      it "should set the proxy_owner_method" do
        @class.proxied_by(:foobar)
        @class.proxy_owner_method.should eql(:foobar)
      end

      it "should raise an error if model name pre-defined" do
        lambda { @class.proxied_by(:object_id) }.should raise_error
      end

      it "should raise an error if object already has a proxy" do
        @class.proxied_by(:department)
        lambda { @class.proxied_by(:company) }.should raise_error
      end

      it "should overwrite the database method to provide an error" do
        @class.proxied_by(:company)
        lambda { @class.database }.should raise_error(StandardError, /database must be accessed via/)
      end
    end

    describe ".proxied_model_names" do
      before do
        @class = Class.new(CouchRest::Model::Base)
      end

      it "should respond to proxied_model_names" do
        @class.should respond_to(:proxied_model_names)
      end

      it "should provide an empty array" do
        @class.proxied_model_names.should be_empty
      end

      it "should accept new entries" do
        @class.proxied_model_names << 'Cat'
        @class.proxied_model_names.first.should eql('Cat')
      end
    end

  end

  describe "ModelProxy" do

    before :all do
      @klass = CouchRest::Model::Proxyable::ModelProxy
    end

    before :each do
      @design_doc = double('Design')
      @design_doc.stub(:view_names).and_return(['all', 'by_name'])
      @model = double('Cat')
      @model.stub(:design_docs).and_return([@design_doc])
      @obj = @klass.new(@model, 'owner', 'owner_name', 'database')
    end

    describe "initialization" do

      it "should set base attributes" do
        @obj.model.should eql(@model)
        @obj.owner.should eql('owner')
        @obj.owner_name.should eql('owner_name')
        @obj.database.should eql('database')
      end

      it "should create view methods" do
        @obj.should respond_to('all')
        @obj.should respond_to('by_name')
        @obj.should respond_to('find_all')
        @obj.should respond_to('find_by_name')
        @obj.should respond_to('find_by_name!')
      end

      it "should create 'all' view method that forward to model's view with proxy" do
        @model.should_receive(:all).with(:proxy => @obj).and_return(nil)
        @obj.all
      end

      it "should create 'by_name' view method that forward to model's view with proxy" do
        @model.should_receive(:by_name).with(:proxy => @obj).and_return(nil)
        @obj.by_name
      end

      it "should create 'find_by_name' view that forwards to normal view" do
        view = double('view')
        view.should_receive('key').with('name').and_return(view)
        view.should_receive('first').and_return(nil)
        @obj.should_receive(:by_name).and_return(view)
        @obj.find_by_name('name')
      end

      it "should create 'find_by_name!' that raises error when there are no results" do
        view = double('view')
        view.should_receive('key').with('name').and_return(view)
        view.should_receive('first').and_return(nil)
        @obj.should_receive(:by_name).and_return(view)
        lambda { @obj.find_by_name!('name') }.should raise_error(CouchRest::Model::DocumentNotFound)
      end

    end

    describe "instance" do

      it "should proxy new call" do
        @obj.should_receive(:proxy_block_update).with(:new, 'attrs', 'opts')
        @obj.new('attrs', 'opts')
      end

      it "should proxy build_from_database" do
        @obj.should_receive(:proxy_block_update).with(:build_from_database, 'attrs', 'opts')
        @obj.build_from_database('attrs', 'opts')
      end

      it "should proxy #count" do
        view = double('View')
        view.should_receive(:count).and_return(nil)
        @model.should_receive(:all).and_return(view)
        @obj.count
      end

      it "should proxy #first" do
        view = double('View')
        view.should_receive(:first).and_return(nil)
        @model.should_receive(:all).and_return(view)
        @obj.first
      end

      it "should proxy #last" do
        view = double('View')
        view.should_receive(:last).and_return(nil)
        @model.should_receive(:all).and_return(view)
        @obj.last
      end

      it "should proxy #get" do
        @model.should_receive(:get).with(32, 'database')
        @obj.should_receive(:proxy_update)
        @obj.get(32)
      end
      it "should proxy #find" do
        @model.should_receive(:get).with(32, 'database')
        @obj.should_receive(:proxy_update)
        @obj.find(32)
      end


      ### Updating methods

      describe "#proxy_update" do
        it "should set returned doc fields" do
          doc = double(:Document)
          doc.should_receive(:is_a?).with(@model).and_return(true)
          doc.should_receive(:database=).with('database')
          doc.should_receive(:model_proxy=).with(@obj)
          doc.should_receive(:send).with('owner_name=', 'owner')
          @obj.send(:proxy_update, doc).should eql(doc)
        end

        it "should not set anything if matching document not provided" do
          doc = double(:DocumentFoo)
          doc.should_receive(:is_a?).with(@model).and_return(false)
          doc.should_not_receive(:database=)
          doc.should_not_receive(:model_proxy=)
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

      describe "#proxy_block_update" do
        it "should proxy block updates" do
          doc = { }
          @obj.model.should_receive(:new).and_yield(doc)
          @obj.should_receive(:proxy_update).with(doc)
          @obj.send(:proxy_block_update, :new)
        end
      end

    end

  end

  describe "scenarios" do

    before :all do
      class ProxyableCompany < CouchRest::Model::Base
        use_database DB
        property :slug
        proxy_for :proxyable_invoices
        def proxy_database(assoc)
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
      view = @company.proxyable_invoices.all
      view.should be_empty
      TEST_SERVER.databases.find{|db| db =~ /#{TESTDB}-samco/}.should_not be_nil
    end

    it "should allow creation of new entries" do
      inv = @company.proxyable_invoices.new(:client => "Lorena", :total => 35)
      # inv.database.should_not be_nil
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
