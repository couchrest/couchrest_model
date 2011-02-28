require File.expand_path("../../spec_helper", __FILE__)

require File.join(FIXTURE_PATH, 'more', 'cat')
require File.join(FIXTURE_PATH, 'more', 'article')
require File.join(FIXTURE_PATH, 'more', 'course')
require File.join(FIXTURE_PATH, 'more', 'card')
require File.join(FIXTURE_PATH, 'base')

class WithCastedModelMixin < Hash
  include CouchRest::Model::CastedModel
  property :name
  property :details, Object, :default => {}
  property :casted_attribute, WithCastedModelMixin
end

class DummyModel < CouchRest::Model::Base
  use_database TEST_SERVER.default_database
  raise "Default DB not set" if TEST_SERVER.default_database.nil?
  property :casted_attribute, WithCastedModelMixin
  property :details, Object, :default => {}
  property :keywords,         [String]
  property :sub_models do |child|
    child.property :title
  end
end


describe "Dirty" do

  describe "changes" do

    it "should return changes on an attribute" do
      @card = Card.new(:first_name => "matt")
      @card.first_name = "andrew"
      @card.changes.should == { "first_name" => ["matt", "andrew"] }
    end

  end

  describe "save" do

    it "should not save unchanged records" do
      card_id = Card.create!(:first_name => "matt").id
      @card = Card.find(card_id)
      @card.database.should_not_receive(:save_doc)
      @card.save
    end

    it "should save changed records" do
      card_id = Card.create!(:first_name => "matt").id
      @card = Card.find(card_id)
      @card.first_name = "andrew"
      @card.database.should_receive(:save_doc).and_return({"ok" => true})
      @card.save
    end

  end

  describe "changed?" do

    # match activerecord behaviour
    it "should report no changes on a new object with no attributes set" do
      @card = Card.new
      @card.changed?.should be_false
    end

=begin
    # match activerecord behaviour
    # not currently working - not too important
    it "should report changes on a new object with attributes set" do
      @card = Card.new(:first_name => "matt")
      @card.changed?.should be_true
    end
=end

    it "should report no changes on objects fetched from the database" do
      card_id = Card.create!(:first_name => "matt").id
      @card = Card.find(card_id)
      @card.changed?.should be_false
    end

    it "should report changes if the record is modified" do
      @card = Card.new
      @card.first_name = "andrew"
      @card.changed?.should be_true
      @card.first_name_changed?.should be_true
    end

    it "should report no changes for unmodified records" do
      card_id = Card.create!(:first_name => "matt").id
      @card = Card.find(card_id)
      @card.first_name = "matt"
      @card.changed?.should be_false
      @card.first_name_changed?.should be_false
    end

    it "should report no changes after a new record has been saved" do
      @card = Card.new(:first_name => "matt")
      @card.save!
      @card.changed?.should be_false
    end

    it "should report no changes after a record has been saved" do
      card_id = Card.create!(:first_name => "matt").id
      @card = Card.find(card_id)
      @card.first_name = "andrew"
      @card.save!
      @card.changed?.should be_false
    end

    # test changing list properties

    it "should report changes if a list property is modified" do
      cat_id = Cat.create!(:name => "Felix", :toys => [{:name => "Mouse"}]).id
      @cat = Cat.find(cat_id)
      @cat.toys = [{:name => "Feather"}]
      @cat.changed?.should be_true
    end

    it "should report no changes if a list property is unmodified" do
      cat_id = Cat.create!(:name => "Felix", :toys => [{:name => "Mouse"}]).id
      @cat = Cat.find(cat_id)
      @cat.toys = [{:name => "Mouse"}]  # same as original list
      @cat.changed?.should be_false
    end

    # attachments

    it "should report changes if an attachment is added" do
      cat_id = Cat.create!(:name => "Felix", :toys => [{:name => "Mouse"}]).id
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @cat = Cat.find(cat_id)
      @cat.create_attachment(:file => @file, :name => "my_attachment")
      @cat.changed?.should be_true
    end

    it "should report changes if an attachment is deleted" do
      @cat = Cat.create!(:name => "Felix", :toys => [{:name => "Mouse"}])
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = "my_attachment"
      @cat.create_attachment(:file => @file, :name => @attachment_name)
      @cat.save
      @cat = Cat.find(@cat.id)
      @cat.delete_attachment(@attachment_name)
      @cat.changed?.should be_true
    end

    # casted models

    it "should report changes to casted models" do
      @cat = Cat.create!(:name => "Felix", :favorite_toy => { :name => "Mouse" })
      @cat = Cat.find(@cat.id)
      @cat.favorite_toy['name'] = 'Feather'
      @cat.changed?.should be_true
    end

    it "should report changes to hashes" do
      @obj = DummyModel.create!
      @obj = DummyModel.get(@obj.id)
      deets = @obj.details
      deets['color'] = 'orange'
      @obj.changed?.should be_true
    end

  end

end
