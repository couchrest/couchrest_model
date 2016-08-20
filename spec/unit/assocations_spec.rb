# encoding: utf-8
require 'spec_helper'

describe "Assocations" do

  describe ".merge_belongs_to_association_options" do
    before :all do
      def SaleInvoice.merge_assoc_opts(*args)
        merge_belongs_to_association_options(*args)
      end
    end

    it "should return a default set of options" do
      o = SaleInvoice.merge_assoc_opts(:cat)
      expect(o[:foreign_key]).to eql('cat_id')
      expect(o[:class_name]).to eql('Cat')
      expect(o[:proxy_name]).to eql('cats')
      expect(o[:proxy]).to eql('Cat') # same as class name
    end

    it "should merge with provided options" do
      o = SaleInvoice.merge_assoc_opts(:cat, :foreign_key => 'somecat_id', :proxy => 'some_cats')
      expect(o[:foreign_key]).to eql('somecat_id')
      expect(o[:proxy]).to eql('some_cats')
    end

    it "should generate a proxy string if proxied" do
      allow(SaleInvoice).to receive(:proxy_owner_method).twice.and_return('company')
      o = SaleInvoice.merge_assoc_opts(:cat)
      expect(o[:proxy]).to eql('self.company.cats')
    end
    
  end

  describe "of type belongs to" do

    before :each do
      @invoice = SaleInvoice.create(:price => 2000)
      @client = Client.create(:name => "Sam Lown")
    end

    it "should create a foreign key property with setter and getter" do
      expect(@invoice.properties.find{|p| p.name == 'client_id'}).not_to be_nil
      expect(@invoice.respond_to?(:client_id)).to be_truthy
      expect(@invoice.respond_to?("client_id=")).to be_truthy
    end

    it "should set the property and provide object when set" do
      @invoice.client = @client
      expect(@invoice.client_id).to eql(@client.id)
      expect(@invoice.client).to eql(@client)
    end

    it "should set the attribute, save and return" do
      @invoice.client = @client
      @invoice.save
      @invoice = SaleInvoice.get(@invoice.id)
      expect(@invoice.client.id).to eql(@client.id)
    end

    it "should remove the association if nil is provided" do
      @invoice.client = @client
      @invoice.client = nil
      expect(@invoice.client_id).to be_nil
    end

    it "should not try to search for association if foreign_key is nil" do
      @invoice.client_id = nil
      expect(Client).not_to receive(:get)
      @invoice.client
    end

    it "should ignore blank ids" do
      @invoice.client_id = ""
      expect(@invoice.client_id).to be_nil
    end

    it "should allow replacement of object after updating key" do
      @invoice.client = @client
      expect(@invoice.client).to eql(@client)
      @invoice.client_id = nil
      expect(@invoice.client).to be_nil
    end

    it "should allow override of foreign key" do
      expect(@invoice.respond_to?(:alternate_client)).to be_truthy
      expect(@invoice.respond_to?("alternate_client=")).to be_truthy
      expect(@invoice.properties.find{|p| p.name == 'alt_client_id'}).not_to be_nil
    end

    it "should allow override of foreign key and save" do
      @invoice.alternate_client = @client
      @invoice.save
      @invoice = SaleInvoice.get(@invoice.id)
      expect(@invoice.alternate_client.id).to eql(@client.id)
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
      expect(@invoice.respond_to?('entry_ids')).to be_truthy
      expect(@invoice.respond_to?('entry_ids=')).to be_truthy
      expect(@invoice.entries.class).to eql(::CouchRest::Model::CollectionOfProxy)
    end

    it "should allow replacement of objects" do
      @invoice.entries = @entries
      expect(@invoice.entries.length).to eql(3)
      expect(@invoice.entry_ids.length).to eql(3)
      expect(@invoice.entries.first).to eql(@entries.first)
      expect(@invoice.entry_ids.first).to eql(@entries.first.id)
    end

    it "should allow ids to be set directly and load entries" do
      @invoice.entry_ids = @entries.collect{|i| i.id}
      expect(@invoice.entries.length).to eql(3)
      expect(@invoice.entries.first).to eql(@entries.first)
      expect(@invoice.changed?).to be_truthy
    end

    it "should ignore blank ids when set directly" do
      @invoice.entry_ids = ["", @entries.first.id]
      expect(@invoice.entry_ids.length).to be(1)
    end

    it "should replace collection if ids replaced" do
      @invoice.entry_ids = @entries.collect{|i| i.id}
      expect(@invoice.entries.length).to eql(3) # load once
      @invoice.entry_ids = @entries[0..1].collect{|i| i.id}
      expect(@invoice.entries.length).to eql(2)
    end

    it "should allow forced collection update if ids changed" do
      @invoice.entry_ids = @entries[0..1].collect{|i| i.id}
      expect(@invoice.entries.length).to eql(2) # load once
      @invoice.entry_ids << @entries[2].id
      expect(@invoice.entry_ids.length).to eql(3)
      expect(@invoice.entries.length).to eql(2) # cached!
      expect(@invoice.entries(true).length).to eql(3)
    end

    it "should empty arrays when nil collection provided" do
      @invoice.entries = @entries
      @invoice.entries = nil
      expect(@invoice.entry_ids).to be_empty
      expect(@invoice.entries).to be_empty
    end

    it "should empty arrays when nil ids array provided" do
      @invoice.entries = @entries
      @invoice.entry_ids = nil
      expect(@invoice.entry_ids).to be_empty
      expect(@invoice.entries).to be_empty
    end

    it "should ignore nil entries" do
      @invoice.entries = [ nil ]
      expect(@invoice.entry_ids).to be_empty
      expect(@invoice.entries).to be_empty
    end

    # Account for dirty tracking
    describe "dirty tracking" do
      it "should register changes on replacement" do
        @invoice.entries = @entries
        expect(@invoice.changed?).to be_truthy
      end
      it "should register changes on push" do
        expect(@invoice.changed?).to be_falsey
        @invoice.entries << @entries[0]
        expect(@invoice.changed?).to be_truthy
      end
      it "should register changes on pop" do
        @invoice.entries << @entries[0]
        @invoice.save
        expect(@invoice.changed?).to be_falsey
        @invoice.entries.pop
        expect(@invoice.changed?).to be_truthy
      end
      it "should register id changes on push" do
        @invoice.entry_ids << @entries[0].id
        expect(@invoice.changed?).to be_truthy
      end
      it "should register id changes on pop" do
        @invoice.entry_ids << @entries[0].id
        @invoice.save
        expect(@invoice.changed?).to be_falsey
        @invoice.entry_ids.pop
        expect(@invoice.changed?).to be_truthy
      end
    end

    describe "proxy" do

      it "should ensure new entries to proxy are matched" do
        @invoice.entries << @entries.first
        expect(@invoice.entry_ids.first).to eql(@entries.first.id)
        expect(@invoice.entries.first).to eql(@entries.first)
        @invoice.entries << @entries[1]
        expect(@invoice.entries.count).to eql(2)
        expect(@invoice.entry_ids.count).to eql(2)
        expect(@invoice.entry_ids.last).to eql(@entries[1].id)
        expect(@invoice.entries.last).to eql(@entries[1])
      end

      it "should support push method" do
        @invoice.entries.push(@entries.first)
        expect(@invoice.entry_ids.first).to eql(@entries.first.id)
      end

      it "should support []= method" do
        @invoice.entries[0] = @entries.first
        expect(@invoice.entry_ids.first).to eql(@entries.first.id)
      end

      it "should support unshift method" do
        @invoice.entries.unshift(@entries.first)
        expect(@invoice.entry_ids.first).to eql(@entries.first.id)
        @invoice.entries.unshift(@entries[1])
        expect(@invoice.entry_ids.first).to eql(@entries[1].id)
      end

      it "should support pop method" do
        @invoice.entries.push(@entries.first)
        expect(@invoice.entries.pop).to eql(@entries.first)
        expect(@invoice.entries.empty?).to be_truthy
        expect(@invoice.entry_ids.empty?).to be_truthy
      end

      it "should support shift method" do
        @invoice.entries.push(@entries[0])
        @invoice.entries.push(@entries[1])
        expect(@invoice.entries.shift).to eql(@entries[0])
        expect(@invoice.entries.first).to eql(@entries[1])
        expect(@invoice.entry_ids.first).to eql(@entries[1].id)
      end

      it "should raise error when adding un-persisted entries" do
        expect(SaleEntry.find_by_description('test entry')).to be_nil
        entry = SaleEntry.new(:description => 'test entry', :price => 500)
        expect {
          @invoice.entries << entry
        }.to raise_error(/Object cannot be added/)
        # In the future maybe?
        # @invoice.save.should be_true
        # SaleEntry.find_by_description('test entry').should_not be_nil
      end

    end

  end

end
