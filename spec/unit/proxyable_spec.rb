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
      expect(@obj).to respond_to(:proxy_database)
    end

    it "should provide proxy database from method" do
      expect(@class).to receive(:proxy_database_method).at_least(:twice).and_return(:slug)
      expect(@obj.proxy_database(:assoc)).to be_a(CouchRest::Database)
      expect(@obj.proxy_database(:assoc).name).to eql('couchrest_proxy')
    end

    it "should raise an error if called and no proxy_database_method set" do
      expect { @obj.proxy_database(:assoc) }.to raise_error(StandardError, /Please set/)
    end

    it "should support passing a suffix" do
      allow(@class).to receive(:proxy_database_method).and_return(:slug)
      allow(@class).to receive(:proxy_database_suffixes).and_return({ assoc: 'suffix' })
      expect { @obj.proxy_database(:assoc) }.not_to raise_error
    end

    it "should join the suffix to the database name" do
      allow(@class).to receive(:proxy_database_method).and_return(:slug)
      allow(@class).to receive(:proxy_database_suffixes).and_return({ assoc: 'suffix' })
      expect(@obj.proxy_database(:assoc).name).to eql('couchrest_proxy_suffix')
    end

    it "should support multiple databases" do
      allow(@class).to receive(:proxy_database_method).and_return(:slug)
      allow(@class).to receive(:proxy_database_suffixes).and_return({ assoc: 'suffix', another_assoc: "another_suffix" })
      expect(@obj.proxy_database(:assoc).name).to eql('couchrest_proxy_suffix')
      expect(@obj.proxy_database(:another_assoc).name).to eql('couchrest_proxy_another_suffix')
    end

    it "should use the configuration's join character to add the suffix" do
      @class.connection.update(:join => '-')
      allow(@class).to receive(:proxy_database_method).and_return(:slug)
      allow(@class).to receive(:proxy_database_suffixes).and_return({ assoc: 'suffix' })
      expect(@obj.proxy_database(:assoc).name).to eql('couchrest-proxy-suffix')
    end

    context "when use_database is set" do
      before do
        @class = Class.new(CouchRest::Model::Base)
        @class.class_eval do
          use_database "another_database"
          def slug; 'proxy'; end
        end
        @obj = @class.new
      end

      it "should provide proxy database from method not considering use database" do
        expect(@class).to receive(:proxy_database_method).at_least(:twice).and_return(:slug)
        expect(@obj.proxy_database(:assoc)).to be_a(CouchRest::Database)
        expect(@obj.proxy_database(:assoc).name).to eql('couchrest_proxy')
      end
    end
  end

  describe "class methods" do


    describe ".proxy_owner_method" do
      before(:each) do
        @class = DummyProxyable.clone
      end
      it "should provide proxy_owner_method accessors" do
        expect(@class).to respond_to(:proxy_owner_method)
        expect(@class).to respond_to(:proxy_owner_method=)
      end
      it "should work as expected" do
        @class.proxy_owner_method = "foo"
        expect(@class.proxy_owner_method).to eql("foo")
      end
    end

    describe ".proxy_database_method" do
      before do
        @class = Class.new(CouchRest::Model::Base)
      end
      it "should be possible to set the proxy database method" do
        @class.proxy_database_method :db
        expect(@class.proxy_database_method).to eql(:db)
      end
    end

    describe ".proxy_for" do
      before(:each) do
        @class = DummyProxyable.clone
      end

      it "should be provided" do
        expect(@class).to respond_to(:proxy_for)
      end

      it "should add model name to proxied model name array" do
        @class.proxy_for(:cats)
        expect(@class.proxied_model_names).to eql(['Cat'])
      end

      it "should add method names to proxied method name array" do
        @class.proxy_for(:cats)
        expect(@class.proxy_method_names).to eql([:cats])
      end

      it "should accept a class_name override" do
        @class.proxy_for(:felines, class_name: "Cat")
        expect(@class.proxy_method_names).to eql([:felines])
        expect(@class.proxied_model_names).to eql(['Cat'])
      end

      describe "proxy database suffix" do
        it "should support not passing a suffix" do
          @class.proxy_for(:cats)
          expect(@class.proxy_database_suffixes).to eql({ cats: nil })
        end

        it "should set the database suffix if provided" do
          @class.proxy_for(:cats, use_suffix: true)
          expect(@class.proxy_database_suffixes).to eql({ cats: 'cats' })
        end

        it "should accept a database suffix override" do
          @class.proxy_for(:cats, database_suffix: 'felines')
          expect(@class.proxy_database_suffixes).to eql({ cats: 'felines' })
        end
      end

      it "should create a new method" do
        allow(DummyProxyable).to receive(:method_defined?).and_return(true)
        DummyProxyable.proxy_for(:cats)
        expect(DummyProxyable.new).to respond_to(:cats)
      end

      describe "generated method" do
        it "should call ModelProxy" do
          DummyProxyable.proxy_for(:cats)
          @obj = DummyProxyable.new
          expect(CouchRest::Model::Proxyable::ModelProxy).to receive(:new).with(Cat, @obj, 'dummy_proxyable', 'db').and_return(true)
          expect(@obj).to receive(:proxy_database).and_return('db')
          @obj.cats
        end

        it "should call class on root namespace" do
          class ::Document < CouchRest::Model::Base
            def self.foo; puts 'bar'; end
          end
          DummyProxyable.proxy_for(:documents)
          @obj = DummyProxyable.new
          expect(CouchRest::Model::Proxyable::ModelProxy).to receive(:new).with(::Document, @obj, 'dummy_proxyable', 'db').and_return(true)
          expect(@obj).to receive('proxy_database').and_return('db')
          @obj.documents
        end
      end
    end

    describe ".proxied_by" do
      before do
        @class = Class.new(CouchRest::Model::Base)
      end

      it "should be provided" do
        expect(@class).to respond_to(:proxied_by)
      end

      it "should add an attribute accessor" do
        @class.proxied_by(:foobar)
        expect(@class.new).to respond_to(:foobar)
      end

      it "should provide #model_proxy method" do
        @class.proxied_by(:foobar)
        expect(@class.new).to respond_to(:model_proxy)
      end

      it "should set the proxy_owner_method" do
        @class.proxied_by(:foobar)
        expect(@class.proxy_owner_method).to eql(:foobar)
      end

      it "should raise an error if model name pre-defined" do
        expect { @class.proxied_by(:object_id) }.to raise_error(/Model can only be proxied once/)
      end

      it "should raise an error if object already has a proxy" do
        @class.proxied_by(:department)
        expect { @class.proxied_by(:company) }.to raise_error(/Model can only be proxied once/)
      end

      it "should overwrite the database method to provide an error" do
        @class.proxied_by(:company)
        expect { @class.database }.to raise_error(StandardError, /database must be accessed via/)
      end
    end

    describe ".proxied_model_names" do
      before do
        @class = Class.new(CouchRest::Model::Base)
      end

      it "should respond to proxied_model_names" do
        expect(@class).to respond_to(:proxied_model_names)
      end

      it "should provide an empty array" do
        expect(@class.proxied_model_names).to be_empty
      end

      it "should accept new entries" do
        @class.proxied_model_names << 'Cat'
        expect(@class.proxied_model_names.first).to eql('Cat')
      end
    end

  end

  describe "ModelProxy" do

    before :all do
      @klass = CouchRest::Model::Proxyable::ModelProxy
    end

    before :each do
      @design_doc = double('Design')
      allow(@design_doc).to receive(:view_names).and_return(['all', 'by_name'])
      @model = double('Cat')
      allow(@model).to receive(:design_docs).and_return([@design_doc])
      @obj = @klass.new(@model, 'owner', 'owner_name', 'database')
    end

    describe "initialization" do

      it "should set base attributes" do
        expect(@obj.model).to eql(@model)
        expect(@obj.owner).to eql('owner')
        expect(@obj.owner_name).to eql('owner_name')
        expect(@obj.database).to eql('database')
      end

      it "should create view methods" do
        expect(@obj).to respond_to('all')
        expect(@obj).to respond_to('by_name')
        expect(@obj).to respond_to('find_all')
        expect(@obj).to respond_to('find_by_name')
        expect(@obj).to respond_to('find_by_name!')
      end

      it "should create 'all' view method that forward to model's view with proxy" do
        expect(@model).to receive(:all).with(:proxy => @obj).and_return(nil)
        @obj.all
      end

      it "should create 'by_name' view method that forward to model's view with proxy" do
        expect(@model).to receive(:by_name).with(:proxy => @obj).and_return(nil)
        @obj.by_name
      end

      it "should create 'find_by_name' view that forwards to normal view" do
        view = double('view')
        expect(view).to receive('key').with('name').and_return(view)
        expect(view).to receive('first').and_return(nil)
        expect(@obj).to receive(:by_name).and_return(view)
        @obj.find_by_name('name')
      end

      it "should create 'find_by_name!' that raises error when there are no results" do
        view = double('view')
        expect(view).to receive('key').with('name').and_return(view)
        expect(view).to receive('first').and_return(nil)
        expect(@obj).to receive(:by_name).and_return(view)
        expect { @obj.find_by_name!('name') }.to raise_error(CouchRest::Model::DocumentNotFound)
      end
    end

    describe "instance" do

      it "should proxy new call" do
        expect(@obj).to receive(:proxy_block_update).with(:new, 'attrs', 'opts')
        @obj.new('attrs', 'opts')
      end

      it "should proxy build_from_database" do
        expect(@obj).to receive(:proxy_block_update).with(:build_from_database, 'attrs', 'opts')
        @obj.build_from_database('attrs', 'opts')
      end

      it "should proxy #count" do
        view = double('View')
        expect(view).to receive(:count).and_return(nil)
        expect(@model).to receive(:all).and_return(view)
        @obj.count
      end

      it "should proxy #first" do
        view = double('View')
        expect(view).to receive(:first).and_return(nil)
        expect(@model).to receive(:all).and_return(view)
        @obj.first
      end

      it "should proxy #last" do
        view = double('View')
        expect(view).to receive(:last).and_return(nil)
        expect(@model).to receive(:all).and_return(view)
        @obj.last
      end

      it "should proxy #get" do
        expect(@model).to receive(:get).with(32, 'database')
        expect(@obj).to receive(:proxy_update)
        @obj.get(32)
      end

      it "should proxy #find" do
        expect(@model).to receive(:get).with(32, 'database')
        expect(@obj).to receive(:proxy_update)
        @obj.find(32)
      end

      it "should proxy factory methods" do
        expect(@model).to receive(:factory_method).with(@obj, "arg_1", "arg_2")
        @obj.factory_method("arg_1", "arg_2")
      end

      it "shouldn't forward undefined model methods" do
        expect { @obj.undefined_factory_method("arg_1", "arg_2") }.to raise_error(NoMethodError, /CouchRest::Model::Proxy/)
      end


      ### Updating methods

      describe "#proxy_update" do
        it "should set returned doc fields" do
          doc = double(:Document)
          expect(doc).to receive(:is_a?).with(@model).and_return(true)
          expect(doc).to receive(:database=).with('database')
          expect(doc).to receive(:model_proxy=).with(@obj)
          expect(doc).to receive(:send).with('owner_name=', 'owner')
          expect(@obj.send(:proxy_update, doc)).to eql(doc)
        end

        it "should not set anything if matching document not provided" do
          doc = double(:DocumentFoo)
          expect(doc).to receive(:is_a?).with(@model).and_return(false)
          expect(doc).not_to receive(:database=)
          expect(doc).not_to receive(:model_proxy=)
          expect(doc).not_to receive(:owner_name=)
          expect(@obj.send(:proxy_update, doc)).to eql(doc)
        end

        it "should pass nil straight through without errors" do
          expect { expect(@obj.send(:proxy_update, nil)).to eql(nil) }.not_to raise_error
        end
      end

      it "#proxy_update_all should update array of docs" do
        docs = [{}, {}]
        expect(@obj).to receive(:proxy_update).twice.with({})
        @obj.send(:proxy_update_all, docs)
      end

      describe "#proxy_block_update" do
        it "should proxy block updates" do
          doc = { }
          expect(@obj.model).to receive(:new).and_yield(doc)
          expect(@obj).to receive(:proxy_update).with(doc)
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
      expect(view).to be_empty
      expect(TEST_SERVER.databases.find{|db| db =~ /#{TESTDB}-samco/}).not_to be_nil
    end

    it "should allow creation of new entries" do
      inv = @company.proxyable_invoices.new(:client => "Lorena", :total => 35)
      # inv.database.should_not be_nil
      expect(inv.save).to be_truthy
      expect(@company.proxyable_invoices.count).to eql(1)
      expect(@company.proxyable_invoices.first.client).to eql("Lorena")
    end

    it "should validate uniqueness" do
      inv = @company.proxyable_invoices.new(:client => "Lorena", :total => 40)
      expect(inv.save).to be_falsey
    end

    it "should allow design views" do
      item = @company.proxyable_invoices.by_total.key(35).first
      expect(item.client).to eql('Lorena')
    end

  end

end
