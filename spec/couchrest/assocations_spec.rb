# encoding: utf-8
require File.expand_path('../../spec_helper', __FILE__)

class Client < CouchRest::ExtendedDocument
  use_database DB

  property :name
  property :tax_code
end

class SaleInvoice < CouchRest::ExtendedDocument  
  use_database DB

  belongs_to :client
  belongs_to :alternate_client, :class_name => 'Client', :foreign_key => 'alt_client_id'

  property :date, Date
  property :price, Integer 
end


describe "Assocations" do

  describe "of type belongs to" do

    before :each do
      @invoice = SaleInvoice.create(:price => "sam", :price => 2000)
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

    it "should raise error if class name does not exist" do
      lambda {
        class TestBadAssoc < CouchRest::ExtendedDocument
          belongs_to :test_bad_item
        end
      }.should raise_error
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

end

