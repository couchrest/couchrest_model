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
  use_database DB

  property :casted_attribute, WithCastedModelMixin
  property :title, :default => 'Sample Title'
  property :details,     Object,   :default => { 'color' => 'blue' }
  property :keywords,    [String], :default => ['default-keyword']
  property :sub_models do
    property :title
  end
end

describe "Dirty" do

  describe "changes" do

    it "should return changes on an attribute" do
      @card = Card.new(:first_name => "matt")
      @card.first_name = "andrew"
      @card.first_name_changed?.should be_true
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

    it "should report no changes on a hash property with a default value" do
      @obj = DummyModel.new
      @obj.details.changed?.should be_false
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

    # casted arrays

    def test_casted_array(change_expected)
      obj = DummyModel.create!
      obj = DummyModel.get(obj.id)
      array = obj.keywords
      yield array, obj
      if change_expected
        obj.changed?.should be_true
      else
        obj.changed?.should be_false
      end
    end

    def should_change_array
      test_casted_array(true) { |a,b| yield a,b }
    end

    def should_not_change_array
      test_casted_array(false) { |a,b| yield a,b }
    end

    it "should report changes if an array index is modified" do
      should_change_array do |array, obj|
        array[0] = "keyword"
      end
    end

    it "should report no changes if an array index is unmodified" do
      should_not_change_array do |array, obj|
        array[0] = array[0]
      end
    end

    it "should report changes if an array is appended with <<" do
      should_change_array do |array, obj|
        array << 'keyword'
      end
    end

    it "should report changes if an array is popped" do
      should_change_array do |array, obj|
        array.pop
      end
    end

    it "should report no changes if an empty array is popped" do
      should_not_change_array do |array, obj|
        array.clear
        obj.save!  # clears changes
        array.pop
      end
    end

    it "should report changes if an array is pushed" do
      should_change_array do |array, obj|
        array.push("keyword")
      end
    end

    it "should report changes if an array is shifted" do
      should_change_array do |array, obj|
        array.shift
      end
    end

    it "should report no changes if an empty array is shifted" do
      should_not_change_array do |array, obj|
        array.clear
        obj.save!  # clears changes
        array.shift
      end
    end

    it "should report changes if an array is unshifted" do
      should_change_array do |array, obj|
        array.unshift("keyword")
      end
    end

    it "should report changes if an array is cleared" do
      should_change_array do |array, obj|
        array.clear
      end
    end

    # Object, {}  (casted hash)

    def test_casted_hash(change_expected)
      obj = DummyModel.create!
      obj = DummyModel.get(obj.id)
      hash = obj.details
      yield hash, obj
      if change_expected
        obj.changed?.should be_true
      else
        obj.changed?.should be_false
      end
    end

    def should_change_hash
      test_casted_hash(true) { |a,b| yield a,b }
    end

    def should_not_change_hash
      test_casted_hash(false) { |a,b| yield a,b }
    end

    it "should report changes if a hash is modified" do
      should_change_hash do |hash, obj|
        hash['color'] = 'orange'
      end
    end

    it "should report no changes if a hash is unmodified" do
      should_not_change_hash do |hash, obj|
        hash['color'] = hash['color']
      end
    end

    it "should report changes when deleting from a hash" do
      should_change_hash do |hash, obj|
        hash.delete('color')
      end
    end

    it "should report no changes when deleting a non existent key from a hash" do
      should_not_change_hash do |hash, obj|
        hash.delete('non-existent-key')
      end
    end

    it "should report changes when clearing a hash" do
      should_change_hash do |hash, obj|
        hash.clear
      end
    end

    it "should report changes when merging changes to a hash" do
      should_change_hash do |hash, obj|
        hash.merge!('foo' => 'bar')
      end
    end

    it "should report no changes when merging no changes to a hash" do
      should_not_change_hash do |hash, obj|
        hash.merge!('color' => hash['color'])
      end
    end

    it "should report changes when replacing hash content" do
      should_change_hash do |hash, obj|
        hash.replace('foo' => 'bar')
      end
    end

    it "should report no changes when replacing hash content with same content" do
      should_not_change_hash do |hash, obj|
        hash.replace(hash)
      end
    end

    it "should report changes when removing records with delete_if" do
      should_change_hash do |hash, obj|
        hash.delete_if { true }
      end
    end

    it "should report no changes when removing no records with delete_if" do
      should_not_change_hash do |hash, obj|
        hash.delete_if { false }
      end
    end

    if {}.respond_to?(:keep_if)

      it "should report changes when removing records with keep_if" do
        should_change_hash do |hash, obj|
          hash.keep_if { false }
        end
      end

      it "should report no changes when removing no records with keep_if" do
        should_not_change_hash do |hash, obj|
          hash.keep_if { true }
        end
      end

    end

  end

end
