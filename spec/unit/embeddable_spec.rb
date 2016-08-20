# encoding: utf-8
require "spec_helper"

class WithCastedModelMixin
  include CouchRest::Model::Embeddable
  property :name
  property :no_value
  property :details, Object, :default => {}
  property :casted_attribute, WithCastedModelMixin
end

class OldFashionedMixin < Hash
  include CouchRest::Model::CastedModel
  property :name
end

class DummyModel < CouchRest::Model::Base
  use_database DB 
  property :casted_attribute, WithCastedModelMixin
  property :keywords,         [String]
  property :old_casted_attribute, OldFashionedMixin
  property :sub_models, :array => true do |child|
    child.property :title
  end
  property :param_free_sub_models, :array => true do
    property :title
  end
end

class WithCastedCallBackModel
  include CouchRest::Model::Embeddable
  property :name
  property :run_before_validation
  property :run_after_validation

  validates_presence_of :run_before_validation

  before_validation do |object|
    object.run_before_validation = true
  end
  after_validation do |object|
    object.run_after_validation = true
  end
end

class CastedCallbackDoc < CouchRest::Model::Base
  use_database DB 
  property :callback_model, WithCastedCallBackModel
end

describe CouchRest::Model::Embeddable do

  describe "isolated" do
    before(:each) do
      @obj = WithCastedModelMixin.new
    end
    it "should automatically include the property mixin and define getters and setters" do
      @obj.name = 'Matt'
      expect(@obj.name).to eq('Matt')
    end

    it "should allow override of default" do
      @obj = WithCastedModelMixin.new(:name => 'Eric', :details => {'color' => 'orange'})
      expect(@obj.name).to eq('Eric')
      expect(@obj.details['color']).to eq('orange')
    end
    it "should always return base_doc? as false" do
      expect(@obj.base_doc?).to be_falsey
    end
    it "should call after_initialize callback if available" do
      klass = Class.new do
        include CouchRest::Model::CastedModel
        after_initialize :set_name
        property :name
        def set_name; self.name = "foobar"; end
      end
      @obj = klass.new
      expect(@obj.name).to eql("foobar")
    end
    it "should allow override of initialize with super" do
      klass = Class.new do
        include CouchRest::Model::Embeddable
        after_initialize :set_name
        property :name
        def set_name; self.name = "foobar"; end
        def initialize(attrs = {}); super(); end
      end
      @obj = klass.new
      expect(@obj.name).to eql("foobar")
    end
  end

  describe "casted as an attribute, but without a value" do
    before(:each) do
      @obj = DummyModel.new
      @casted_obj = @obj.casted_attribute
    end
    it "should be nil" do
      expect(@casted_obj).to eq(nil)
    end
  end

  describe "anonymous sub casted models" do
    before :each do
      @obj = DummyModel.new
    end
    it "should be empty initially" do
      expect(@obj.sub_models).not_to be_nil
      expect(@obj.sub_models).to be_empty
    end
    it "should be updatable using a hash" do
      @obj.sub_models << {:title => 'test'}
      expect(@obj.sub_models.first.title).to eql('test')
    end
    it "should be empty intitally (without params)" do
      expect(@obj.param_free_sub_models).not_to be_nil
      expect(@obj.param_free_sub_models).to be_empty
    end
    it "should be updatable using a hash (without params)" do
      @obj.param_free_sub_models << {:title => 'test'}
      expect(@obj.param_free_sub_models.first.title).to eql('test')
    end
  end

  describe "casted as attribute" do
    before(:each) do
      casted = {:name => 'not whatever'}
      @obj = DummyModel.new(:casted_attribute => {:name => 'whatever', :casted_attribute => casted})
      @casted_obj = @obj.casted_attribute
    end

    it "should be available from its parent" do
      expect(@casted_obj).to be_an_instance_of(WithCastedModelMixin)
    end

    it "should have the getters defined" do
      expect(@casted_obj.name).to eq('whatever')
    end

    it "should know who casted it" do
      expect(@casted_obj.casted_by).to eq(@obj)
    end

    it "should know which property casted it" do
      expect(@casted_obj.casted_by_property).to eq(@obj.properties.detect{|p| p.to_s == 'casted_attribute'})
    end

    it "should return nil for the 'no_value' attribute" do
      expect(@casted_obj.no_value).to be_nil
    end

    it "should return nil for the unknown attribute" do
      expect(@casted_obj["unknown"]).to be_nil
    end

    it "should return {} for the hash attribute" do
      expect(@casted_obj.details).to eq({})
    end

    it "should cast its own attributes" do
      expect(@casted_obj.casted_attribute).to be_instance_of(WithCastedModelMixin)
    end

    it "should raise an error if save or update_attributes called" do
      expect { @casted_obj.casted_attribute.save }.to raise_error(NoMethodError)
      expect { @casted_obj.casted_attribute.update_attributes(:name => "Fubar") }.to raise_error(NoMethodError)
    end
  end

  # Basic testing for an old fashioned casted hash
  describe "old hash casted as attribute" do
    before :each do
      @obj = DummyModel.new(:old_casted_attribute => {:name => 'Testing'})
      @casted_obj = @obj.old_casted_attribute
    end
    it "should be available from its parent" do
      expect(@casted_obj).to be_an_instance_of(OldFashionedMixin)
    end

    it "should have the getters defined" do
      expect(@casted_obj.name).to eq('Testing')
    end

    it "should know who casted it" do
      expect(@casted_obj.casted_by).to eq(@obj)
    end

    it "should know which property casted it" do
      expect(@casted_obj.casted_by_property).to eq(@obj.properties.detect{|p| p.to_s == 'old_casted_attribute'})
    end

    it "should return nil for the unknown attribute" do
      expect(@casted_obj["unknown"]).to be_nil
    end
  end

  describe "casted as an array of a different type" do
    before(:each) do
      @obj = DummyModel.new(:keywords => ['couch', 'sofa', 'relax', 'canapé'])
    end

    it "should cast the array properly" do
      expect(@obj.keywords).to be_kind_of(Array)
      expect(@obj.keywords.first).to eq('couch')
    end
  end

  describe "update attributes without saving" do
    before(:each) do
      @question = Question.new(:q => "What is your quest?", :a => "To seek the Holy Grail")
    end
    it "should work for write_attributes method" do
      expect(@question.q).to eq("What is your quest?")
      expect(@question['a']).to eq("To seek the Holy Grail")
      @question.write_attributes(
        :q => "What is your favorite color?", 'a' => "Blue"
      )
      expect(@question['q']).to eq("What is your favorite color?")
      expect(@question.a).to eq("Blue")
    end

    it "should also work for attributes= alias" do
      expect(@question.respond_to?(:attributes=)).to be_truthy
      @question.attributes = {:q => "What is your favorite color?", 'a' => "Blue"}
      expect(@question['q']).to eq("What is your favorite color?")
      expect(@question.a).to eq("Blue")
    end

    it "should flip out if an attribute= method is missing" do
      expect {
        @q.attributes = { 'foo' => "something", :a => "No green" }
      }.to raise_error(NoMethodError)
    end

    it "should not change any attributes if there is an error" do
      expect {
        @q.attributes = { 'foo' => "something", :a => "No green" }
      }.to raise_error(NoMethodError)
      expect(@question.q).to eq("What is your quest?")
      expect(@question.a).to eq("To seek the Holy Grail")
    end

  end

  describe "saved document with casted models" do
    before(:each) do
      reset_test_db!
      @obj = DummyModel.new(:casted_attribute => {:name => 'whatever'})
      expect(@obj.save).to be_truthy
      @obj = DummyModel.get(@obj.id)
    end

    it "should be able to load with the casted models" do
      casted_obj = @obj.casted_attribute
      expect(casted_obj).not_to be_nil
      expect(casted_obj).to be_an_instance_of(WithCastedModelMixin)
    end

    it "should have defined getters for the casted model" do
      casted_obj = @obj.casted_attribute
      expect(casted_obj.name).to eq("whatever")
    end

    it "should have defined setters for the casted model" do
      casted_obj = @obj.casted_attribute
      casted_obj.name = "test"
      expect(casted_obj.name).to eq("test")
    end

    it "should retain an override of a casted model attribute's default" do
      casted_obj = @obj.casted_attribute
      casted_obj.details['color'] = 'orange'
      @obj.save
      casted_obj = DummyModel.get(@obj.id).casted_attribute
      expect(casted_obj.details['color']).to eq('orange')
    end

  end

  describe "saving document with array of casted models and validation" do
    before :each do
      @cat = Cat.new :name => "felix"
      @cat.save
    end

    it "should save" do
      toy = CatToy.new :name => "Mouse"
      @cat.toys.push(toy)
      expect(@cat.save).to be_truthy
      @cat = Cat.get @cat.id
      expect(@cat.toys.class).to eq(CouchRest::Model::CastedArray)
      expect(@cat.toys.first.class).to eq(CatToy)
      expect(@cat.toys.first).to be === toy
    end

    it "should fail because name is not present" do
      toy = CatToy.new
      @cat.toys.push(toy)
      expect(@cat).not_to be_valid
      expect(@cat.save).to be_falsey
    end

    it "should not fail if the casted model doesn't have validation" do
      Cat.property :masters, [Person], :default => []
      Cat.validates_presence_of :name
      cat = Cat.new(:name => 'kitty')
      expect(cat).to be_valid
      cat.masters.push Person.new
      expect(cat).to be_valid
    end
  end

  describe "calling valid?" do
    before :each do
      @cat = Cat.new
      @toy1 = CatToy.new
      @toy2 = CatToy.new
      @toy3 = CatToy.new
      @cat.favorite_toy = @toy1
      @cat.toys << @toy2
      @cat.toys << @toy3
    end

    describe "on the top document" do
      it "should put errors on all invalid casted models" do
        expect(@cat).not_to be_valid
        expect(@cat.errors).not_to be_empty
        expect(@toy1.errors).not_to be_empty
        expect(@toy2.errors).not_to be_empty
        expect(@toy3.errors).not_to be_empty
      end

      it "should not put errors on valid casted models" do
        @toy1.name = "Feather"
        @toy2.name = "Twine"
        expect(@cat).not_to be_valid
        expect(@cat.errors).not_to be_empty
        expect(@toy1.errors).to be_empty
        expect(@toy2.errors).to be_empty
        expect(@toy3.errors).not_to be_empty
      end

      it "should not use dperecated ActiveModel options" do
        expect(ActiveSupport::Deprecation).not_to receive(:warn)
        expect(@cat).not_to be_valid
      end
    end

    describe "on a casted model property" do
      it "should only validate itself" do
        expect(@toy1).not_to be_valid
        expect(@toy1.errors).not_to be_empty
        expect(@cat.errors).to be_empty
        expect(@toy2.errors).to be_empty
        expect(@toy3.errors).to be_empty
      end
    end

    describe "on a casted model inside a casted collection" do
      it "should only validate itself" do
        expect(@toy2).not_to be_valid
        expect(@toy2.errors).not_to be_empty
        expect(@cat.errors).to be_empty
        expect(@toy1.errors).to be_empty
        expect(@toy3.errors).to be_empty
      end
    end
  end

  describe "calling new? on a casted model" do
    before :each do
      reset_test_db!
      @cat = Cat.new(:name => 'Sockington')
      @favorite_toy = CatToy.new(:name => 'Catnip Ball')
      @cat.favorite_toy = @favorite_toy
      @cat.toys << CatToy.new(:name => 'Fuzzy Stick')
    end

    it "should be true on new" do
      expect(CatToy.new).to be_new
      expect(CatToy.new.new_record?).to be_truthy
    end

    it "should be true after assignment" do
      expect(@cat).to be_new
      expect(@cat.favorite_toy).to be_new
      expect(@cat.toys.first).to be_new
    end

    it "should not be true after create or save" do
      @cat.create
      @cat.save
      expect(@cat.favorite_toy).not_to be_new
      expect(@cat.toys.first.casted_by).to eql(@cat)
      expect(@cat.toys.first).not_to be_new
    end

    it "should not be true after get from the database" do
      @cat.save
      @cat = Cat.get(@cat.id)
      expect(@cat.favorite_toy).not_to be_new
      expect(@cat.toys.first).not_to be_new
    end

    it "should still be true after a failed create or save" do
      @cat.name = nil
      expect(@cat.create).to be_falsey
      expect(@cat.save).to be_falsey
      expect(@cat.favorite_toy).to be_new
      expect(@cat.toys.first).to be_new
    end
  end

  describe "calling base_doc from a nested casted model" do
    before :each do
      @course = Course.new(:title => 'Science 101')
      @professor = Person.new(:name => ['Professor', 'Plum'])
      @cat = Cat.new(:name => 'Scratchy')
      @toy1 = CatToy.new
      @toy2 = CatToy.new
      @course.professor = @professor
      @professor.pet = @cat
      @cat.favorite_toy = @toy1
      @cat.toys << @toy2
    end

    it 'should let you copy over casted arrays' do
      question = Question.new
      @course.questions << question
      new_course = Course.new
      new_course.questions = @course.questions
      expect(new_course.questions).to include(question)
    end

    it "should reference the top document for" do
      expect(@course.base_doc).to be === @course
      expect(@professor.casted_by).to be === @course
      expect(@professor.base_doc).to be === @course
      expect(@cat.base_doc).to be === @course
      expect(@toy1.base_doc).to be === @course
      expect(@toy2.base_doc).to be === @course
    end

    it "should call setter on top document" do
      expect(@toy1.base_doc).not_to be_nil
      @toy1.base_doc.title = 'Tom Foolery'
      expect(@course.title).to eq('Tom Foolery')
    end

    it "should return nil if not yet casted" do
      person = Person.new
      expect(person.base_doc).to eq(nil)
    end
  end

  describe "calling base_doc.save from a nested casted model" do
    before :each do
      reset_test_db!
      @cat = Cat.new(:name => 'Snowball')
      @toy = CatToy.new
      @cat.favorite_toy = @toy
    end

    it "should not save parent document when casted model is invalid" do
      expect(@toy).not_to be_valid
      expect(@toy.base_doc.save).to be_falsey
      expect{@toy.base_doc.save!}.to raise_error(/Validation Failed/)
    end

    it "should save parent document when nested casted model is valid" do
      @toy.name = "Mr Squeaks"
      expect(@toy).to be_valid
      expect(@toy.base_doc.save).to be_truthy
      expect{@toy.base_doc.save!}.not_to raise_error
    end
  end

  describe "callbacks" do
    before(:each) do
      @doc = CastedCallbackDoc.new
      @model = WithCastedCallBackModel.new
      @doc.callback_model = @model
    end

    describe "validate" do
      it "should run before_validation before validating" do
        expect(@model.run_before_validation).to be_nil
        expect(@model).to be_valid
        expect(@model.run_before_validation).to be_truthy
      end
      it "should run after_validation after validating" do
        expect(@model.run_after_validation).to be_nil
        expect(@model).to be_valid
        expect(@model.run_after_validation).to be_truthy
      end
    end
  end
end
