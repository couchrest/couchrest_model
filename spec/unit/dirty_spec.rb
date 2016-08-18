require "spec_helper"

class WithCastedModelMixin
  include CouchRest::Model::CastedModel
  property :name
  property :details, Object, :default => {}
  property :casted_attribute, WithCastedModelMixin
end 

class DirtyModel < CouchRest::Model::Base
  use_database DB

  property :casted_attribute, WithCastedModelMixin
  property :title, :default => 'Sample Title'
  property :details,     Object,   :default => { 'color' => 'blue' }
  property :keywords,    [String], :default => ['default-keyword']
  property :sub_models, :array => true do
    property :title
  end
end

class DirtyUniqueIdModel < CouchRest::Model::Base
  use_database DB
  attr_accessor :code
  unique_id :code
  property :title, String, :default => "Sample Title"
  timestamps!

  def code; self['_id'] || @code; end
end

describe "Dirty" do

  describe "changes" do

    context "when new record" do
      it "should return changes on an attribute" do
        @card = Card.new(:first_name => "matt")
        @card.first_name = "andrew"
        @card.first_name_changed?.should be_true
        @card.changes.should == [ ["+", "first_name", "andrew"] ]
      end
    end

    context "when persisted" do
      it "should return changes on an attribute" do
        @card = Card.create!(:first_name => "matt")
        @card.first_name = "andrew"
        @card.first_name_changed?.should be_true
        @card.changes.should == [["~", "first_name", "matt", "andrew"]]
      end
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
      expect(@card.changed?).to be_false
    end

    it "should report no changes on a hash property with a default value" do
      @obj = DirtyModel.new
      expect(@obj.details_changed?).to be_false
    end

    # match activerecord behaviour
    it "should report changes on a new object with attributes set" do
      @card = Card.new(:first_name => "matt")
      @card.changed?.should be_true
    end

    it "should report no changes on new object with 'unique_id' set" do
      @obj = DirtyUniqueIdModel.new
      @obj.changed?.should be_false
      @obj.changes.should be_empty
    end

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

    it 'should report changes if the record is modified by attributes' do
      @card = Card.new
      @card.attributes = {:first_name => 'danny'}
      @card.changed?.should be_true
      @card.first_name_changed?.should be_true
    end

    it 'should report no changes if the record is modified with an invalid property by attributes' do
      @card = Card.new
      @card.attributes = {:middle_name => 'danny'}
      @card.changed?.should be_false
      @card.first_name_changed?.should be_false
    end

    it "should report no changes if the record is modified with update_attributes" do
      @card = Card.new
      @card.update_attributes(:first_name => 'henry')
      @card.changed?.should be_false
    end

    it "should report no changes if the record is modified with an invalid property by update_attributes" do
      @card = Card.new
      @card.update_attributes(:middle_name => 'peter')
      @card.changed?.should be_false
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
      @cat.favorite_toy.name = 'Feather'
      @cat.changed?.should be_true
    end

    it "should report changes to casted model in array" do
      @obj = Cat.create!(:name => 'felix', :toys => [{:name => "Catnip"}])
      @obj = Cat.get(@obj.id)
      expect(@obj.toys.first.name).to eql('Catnip')
      expect(@obj.toys.first.changed?).to be_false
      expect(@obj.changed?).to be_false
      @obj.toys.first.name = "Super Catnip"
      expect(@obj.toys.first.changed?).to be_true
      expect(@obj.changed?).to be_true
    end

    it "should report changes to anonymous casted models in array" do
      @obj = DirtyModel.create!(:sub_models => [{:title => "Sample"}])
      @obj = DirtyModel.get(@obj.id)
      @obj.sub_models.first.title.should eql("Sample")
      @obj.sub_models.first.changed?.should be_false
      @obj.changed?.should be_false
      @obj.sub_models.first.title = "Another Sample"
      @obj.sub_models.first.changed?.should be_true
      @obj.changed?.should be_true
    end

    # casted arrays

    def test_casted_array(change_expected)
      obj = DirtyModel.create!
      obj = DirtyModel.get(obj.id)
      array = obj.keywords
      yield array, obj
      if change_expected
        expect(obj.changed?).to be_true
      else
        expect(obj.changed?).to be_false
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

    it "should report changes if item is inserted into array" do
      should_change_array do |array, obj|
        array.insert(0, 'keyword')
        obj.keywords[0].should eql('keyword')
      end
    end

    it "should report changes if items are inserted into array" do
      should_change_array do |array, obj|
        array.insert(1, 'keyword', 'keyword2')
        obj.keywords[2].should eql('keyword2')
      end
    end

    it "should report changes if an array is popped" do
      should_change_array do |array, obj|
        array.pop
      end
    end

    it "should report changes if an array is popped after reload" do
      should_change_array do |array, obj|
        obj.reload
        obj.keywords.pop
      end
    end


    it "should report no changes if an empty array is popped" do
      should_not_change_array do |array, obj|
        array.clear
        obj.save!  # clears changes
        array.pop
      end
    end

    it "should report changes on deletion from an array" do
      should_change_array do |array, obj|
        array << "keyword"
        obj.save!
        array.delete_at(0)
      end

      should_change_array do |array, obj|
        array << "keyword"
        obj.save!
        array.delete("keyword")
      end
    end

    it "should report changes on deletion from an array after reload" do
      # NOTE: we don't use array help here as the object is different after reload!
      should_change_array do |array, obj|
        obj.keywords << "keyword"
        obj.save!
        obj.reload
        obj.keywords.delete_at(0)
      end

      should_change_array do |array, obj|
        obj.keywords << "keyword"
        obj.save!
        obj.reload
        obj.keywords.delete("keyword")
        puts "CHANGES: #{obj.changes}"
      end
    end

    it "should report no changes on deletion from an empty array" do
      should_not_change_array do |array, obj|
        array.clear
        obj.save!
        array.delete_at(0)
      end

      should_not_change_array do |array, obj|
        array.clear
        obj.save!
        array.delete("keyword")
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
      obj = DirtyModel.create!
      obj = DirtyModel.get(obj.id)
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


  describe "when mass_assign_any_attribute true" do
    before(:each) do
      # dupe Card class so that no other tests are effected
      card_class = Card.dup
      card_class.class_eval do
        mass_assign_any_attribute true
      end
      @card = card_class.new(:first_name => 'Sam')
    end

    it "should report no changes if the record is modified with update_attributes" do
      @card.update_attributes(:other_name => 'henry')
      @card.changed?.should be_false
    end

    it "should report not new if the record is modified with update_attributes" do
      @card.update_attributes(:other_name => 'henry')
      @card.new?.should be_false
    end

    it 'should report changes when updated with attributes' do
      @card.save
      @card.attributes = {:testing => 'fooobar'}
      @card.changed?.should be_true
    end

    it 'should report changes when updated with a known property' do
      @card.save
      @card.first_name = 'Danny'
      @card.changed?.should be_true
    end

    it "should not report changes if property is updated with same value" do
      @card.update_attributes :testing => 'fooobar'
      @card.attributes = {'testing' => 'fooobar'}
      @card.changed?.should be_false
    end

  end

end
