# encoding: utf-8
require File.expand_path('../../spec_helper', __FILE__)
require File.join(FIXTURE_PATH, 'more', 'sale_invoice')


describe "Assocations" do

  describe ".merge_belongs_to_association_options" do
    before :all do
      def SaleInvoice.merge_assoc_opts(*args)
        merge_belongs_to_association_options(*args)
      end
    end

    it "should return a default set of options" do
      o = SaleInvoice.merge_assoc_opts(:cat)
      o[:foreign_key].should eql('cat_id')
      o[:class_name].should eql('Cat')
      o[:proxy_name].should eql('cats')
      o[:proxy].should eql('Cat') # same as class name
    end

    it "should merge with provided options" do
      o = SaleInvoice.merge_assoc_opts(:cat, :foreign_key => 'somecat_id', :proxy => 'some_cats')
      o[:foreign_key].should eql('somecat_id')
      o[:proxy].should eql('some_cats')
    end

    it "should generate a proxy string if proxied" do
      SaleInvoice.stub!(:proxy_owner_method).twice.and_return('company')
      o = SaleInvoice.merge_assoc_opts(:cat)
      o[:proxy].should eql('self.company.cats')
    end
    
  end

  describe "of type belongs to" do

    before :each do
      @invoice = SaleInvoice.create(:price => 2000)
      @client = Client.create(:name => "Sam Lown")
    end

    it "should create a foreign key property with setter and getter" do
      @invoice.properties.find{|p| p.name == 'client_id'}.should_not be_nil
      @invoice.respond_to?(:client_id).should be_true
      @invoice.respond_to?("client_id=").should be_true
    end

    it "should set the property and provide object when set" do
      @invoice.client = @client
      @invoice.client_id.should eql(@client.id)
      @invoice.client.should eql(@client)
    end

    it "should set the attribute, save and return" do
      @invoice.client = @client
      @invoice.save
      @invoice = SaleInvoice.get(@invoice.id)
      @invoice.client.id.should eql(@client.id)
    end

    it "should remove the association if nil is provided" do
      @invoice.client = @client
      @invoice.client = nil
      @invoice.client_id.should be_nil
    end

    it "should not try to search for association if foreign_key is nil" do
      @invoice.client_id = nil
      Client.should_not_receive(:get)
      @invoice.client
    end

    it "should allow override of foreign key" do
      @invoice.respond_to?(:alternate_client).should be_true
      @invoice.respond_to?("alternate_client=").should be_true
      @invoice.properties.find{|p| p.name == 'alt_client_id'}.should_not be_nil
    end

    it "should allow override of foreign key and save" do
      @invoice.alternate_client = @client
      @invoice.save
      @invoice = SaleInvoice.get(@invoice.id)
      @invoice.alternate_client.id.should eql(@client.id)
    end

  end

  describe "of type collection_of" do

    before(:each) do
      @invoice = SaleInvoice.create(:price => 2000)
      @entries = [
        SaleEntry.create(:description => 'test line 1', :price => 500),
        SaleEntry.create(:description => 'test line 2', :price => 500),
        SaleEntry.create(:description => 'test line 3', :price => 1000)
      ]
    end

    it "should create an associated property and collection proxy" do
      @invoice.respond_to?('entry_ids').should be_true
      @invoice.respond_to?('entry_ids=').should be_true
      @invoice.entries.class.should eql(::CouchRest::Model::CollectionOfProxy)
    end

    it "should allow replacement of objects" do
      @invoice.entries = @entries
      @invoice.entries.length.should eql(3)
      @invoice.entry_ids.length.should eql(3)
      @invoice.entries.first.should eql(@entries.first)
      @invoice.entry_ids.first.should eql(@entries.first.id)
    end

    it "should allow ids to be set directly and load entries" do
      @invoice.entry_ids = @entries.collect{|i| i.id}
      @invoice.entries.length.should eql(3)
      @invoice.entries.first.should eql(@entries.first)
    end

    it "should replace collection if ids replaced" do
      @invoice.entry_ids = @entries.collect{|i| i.id}
      @invoice.entries.length.should eql(3) # load once
      @invoice.entry_ids = @entries[0..1].collect{|i| i.id}
      @invoice.entries.length.should eql(2)
    end

    it "should allow forced collection update if ids changed" do
      @invoice.entry_ids = @entries[0..1].collect{|i| i.id}
      @invoice.entries.length.should eql(2) # load once
      @invoice.entry_ids << @entries[2].id
      @invoice.entry_ids.length.should eql(3)
      @invoice.entries.length.should eql(2) # cached!
      @invoice.entries(true).length.should eql(3)
    end

    it "should empty arrays when nil collection provided" do
      @invoice.entries = @entries
      @invoice.entries = nil
      @invoice.entry_ids.should be_empty
      @invoice.entries.should be_empty
    end

    it "should empty arrays when nil ids array provided" do
      @invoice.entries = @entries
      @invoice.entry_ids = nil
      @invoice.entry_ids.should be_empty
      @invoice.entries.should be_empty
    end

    it "should ignore nil entries" do
      @invoice.entries = [ nil ]
      @invoice.entry_ids.should be_empty
      @invoice.entries.should be_empty
    end

    # Account for dirty tracking
    describe "dirty tracking" do
      it "should register changes on push" do
        @invoice.changed?.should be_false
        @invoice.entries << @entries[0]
        @invoice.changed?.should be_true
      end
      it "should register changes on pop" do
        @invoice.entries << @entries[0]
        @invoice.save
        @invoice.changed?.should be_false
        @invoice.entries.pop
        @invoice.changed?.should be_true
      end
      it "should register id changes on push" do
        @invoice.entry_ids << @entries[0].id
        @invoice.changed?.should be_true
      end
      it "should register id changes on pop" do
        @invoice.entry_ids << @entries[0].id
        @invoice.save
        @invoice.changed?.should be_false
        @invoice.entry_ids.pop
        @invoice.changed?.should be_true
      end
    end

    describe "proxy" do

      it "should ensure new entries to proxy are matched" do
        @invoice.entries << @entries.first
        @invoice.entry_ids.first.should eql(@entries.first.id)
        @invoice.entries.first.should eql(@entries.first)
        @invoice.entries << @entries[1]
        @invoice.entries.count.should eql(2)
        @invoice.entry_ids.count.should eql(2)
        @invoice.entry_ids.last.should eql(@entries[1].id)
        @invoice.entries.last.should eql(@entries[1])
      end

      it "should support push method" do
        @invoice.entries.push(@entries.first)
        @invoice.entry_ids.first.should eql(@entries.first.id)
      end

      it "should support []= method" do
        @invoice.entries[0] = @entries.first
        @invoice.entry_ids.first.should eql(@entries.first.id)
      end

      it "should support unshift method" do
        @invoice.entries.unshift(@entries.first)
        @invoice.entry_ids.first.should eql(@entries.first.id)
        @invoice.entries.unshift(@entries[1])
        @invoice.entry_ids.first.should eql(@entries[1].id)
      end

      it "should support pop method" do
        @invoice.entries.push(@entries.first)
        @invoice.entries.pop.should eql(@entries.first)
        @invoice.entries.empty?.should be_true
        @invoice.entry_ids.empty?.should be_true
      end

      it "should support shift method" do
        @invoice.entries.push(@entries[0])
        @invoice.entries.push(@entries[1])
        @invoice.entries.shift.should eql(@entries[0])
        @invoice.entries.first.should eql(@entries[1])
        @invoice.entry_ids.first.should eql(@entries[1].id)
      end

      it "should raise error when adding un-persisted entries" do
        SaleEntry.find_by_description('test entry').should be_nil
        entry = SaleEntry.new(:description => 'test entry', :price => 500)
        lambda {
          @invoice.entries << entry
        }.should raise_error
        # In the future maybe?
        # @invoice.save.should be_true
        # SaleEntry.find_by_description('test entry').should_not be_nil
      end

    end

  end

end
