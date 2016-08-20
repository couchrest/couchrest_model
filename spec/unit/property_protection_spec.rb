require "spec_helper"

describe "Model Attributes" do

  describe "no declarations" do
    class NoProtection < CouchRest::Model::Base
      use_database DB 
      property :name
      property :phone
    end

    it "should not protect anything through new" do
      user = NoProtection.new(:name => "will", :phone => "555-5555")

      expect(user.name).to eq("will")
      expect(user.phone).to eq("555-5555")
    end

    it "should not protect anything through attributes=" do
      user = NoProtection.new
      user.attributes = {:name => "will", :phone => "555-5555"}

      expect(user.name).to eq("will")
      expect(user.phone).to eq("555-5555")
    end

    it "should recreate from the database properly" do
      user = NoProtection.new
      user.name = "will"
      user.phone = "555-5555"
      user.save!

      user = NoProtection.get(user.id)
      expect(user.name).to eq("will")
      expect(user.phone).to eq("555-5555")
    end

    it "should provide a list of all properties as accessible" do
      user = NoProtection.new(:name => "will", :phone => "555-5555")
      expect(user.accessible_properties.length).to eql(2)
      expect(user.protected_properties).to be_empty
    end
  end

  describe "Model Base", "accessible flag" do
    class WithAccessible < CouchRest::Model::Base
      use_database DB
      property :name, :accessible => true
      property :admin, :default => false
    end

    it { expect { WithAccessible.new(nil) }.to_not raise_error }

    it "should recognize accessible properties" do
      props = WithAccessible.accessible_properties.map { |prop| prop.name}
      expect(props).to include("name")
      expect(props).not_to include("admin")
    end

    it "should protect non-accessible properties set through new" do
      user = WithAccessible.new(:name => "will", :admin => true)

      expect(user.name).to eq("will")
      expect(user.admin).to eq(false)
    end

    it "should protect non-accessible properties set through attributes=" do
      user = WithAccessible.new
      user.attributes = {:name => "will", :admin => true}

      expect(user.name).to eq("will")
      expect(user.admin).to eq(false)
    end
    
    it "should provide correct accessible and protected property lists" do
      user = WithAccessible.new(:name => 'will', :admin => true)
      expect(user.accessible_properties.map{|p| p.to_s}).to eql(['name'])
      expect(user.protected_properties.map{|p| p.to_s}).to eql(['admin'])
    end
  end

  describe "Model Base", "protected flag" do
    class WithProtected < CouchRest::Model::Base
      use_database DB
      property :name
      property :admin, :default => false, :protected => true
    end

    it { expect { WithProtected.new(nil) }.to_not raise_error }

    it "should recognize protected properties" do
      props = WithProtected.protected_properties.map { |prop| prop.name}
      expect(props).not_to include("name")
      expect(props).to include("admin")
    end

    it "should protect non-accessible properties set through new" do
      user = WithProtected.new(:name => "will", :admin => true)

      expect(user.name).to eq("will")
      expect(user.admin).to eq(false)
    end

    it "should protect non-accessible properties set through attributes=" do
      user = WithProtected.new
      user.attributes = {:name => "will", :admin => true}

      expect(user.name).to eq("will")
      expect(user.admin).to eq(false)
    end

    it "should not modify the provided attribute hash" do
      user = WithProtected.new
      attrs = {:name => "will", :admin => true}
      user.attributes = attrs
      expect(attrs[:admin]).to be_truthy
      expect(attrs[:name]).to eql('will')
    end

    it "should provide correct accessible and protected property lists" do
      user = WithProtected.new(:name => 'will', :admin => true)
      expect(user.accessible_properties.map{|p| p.to_s}).to eql(['name'])
      expect(user.protected_properties.map{|p| p.to_s}).to eql(['admin'])
    end

  end

  describe "Model Base", "mixing protected and accessible flags" do
    class WithBothAndUnspecified < CouchRest::Model::Base
      use_database DB
      property :name, :accessible => true
      property :admin, :default => false, :protected => true
      property :phone, :default => 'unset phone number'
    end

    it { expect { WithBothAndUnspecified.new }.to_not raise_error }

    it 'should assume that any unspecified property is protected by default' do
      user = WithBothAndUnspecified.new(:name => 'will', :admin => true, :phone => '555-1234')

      expect(user.name).to eq('will')
      expect(user.admin).to eq(false)
      expect(user.phone).to eq('unset phone number')
    end

  end

  describe "from database" do
    class WithProtected < CouchRest::Model::Base
      use_database DB
      property :name
      property :admin, :default => false, :protected => true
      design do
        view :by_name
      end
    end

    before(:each) do
      @user = WithProtected.new
      @user.name = "will"
      @user.admin = true
      @user.save!
    end

    def verify_attrs(user)
      expect(user.name).to  eq("will")
      expect(user.admin).to eq(true)
    end

    it "Base#get should not strip protected attributes" do
      reloaded = WithProtected.get( @user.id )
      verify_attrs reloaded
    end

    it "Base#get! should not strip protected attributes" do
      reloaded = WithProtected.get!( @user.id )
      verify_attrs reloaded
    end

    it "Base#all should not strip protected attributes" do
      # all creates a CollectionProxy
      docs = WithProtected.all(:key => @user.id)
      expect(docs.length).to eq(1)
      reloaded = docs.first
      verify_attrs reloaded
    end

    it "views should not strip protected attributes" do
      docs = WithProtected.by_name(:startkey => "will", :endkey => "will")
      reloaded = docs.first
      verify_attrs reloaded
    end
  end
end
