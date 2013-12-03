# encoding: utf-8
require 'spec_helper'

describe CouchRest::Model::Persistence do

  before(:each) do
    @obj = WithDefaultValues.new
  end

  describe "creating a new document from database" do

    it "should instantialize" do
      doc = Article.build_from_database({'_id' => 'testitem1', '_rev' => 123, 'couchrest-type' => 'Article', 'name' => 'my test'})
      doc.class.should eql(Article)
    end

    it "should instantialize of same class if no couchrest-type included from DB" do
      doc = Article.build_from_database({'_id' => 'testitem1', '_rev' => 123, 'name' => 'my test'})
      doc.class.should eql(Article)
    end

    it "should instantiate document of different type" do
      doc = Article.build_from_database({'_id' => 'testitem2', '_rev' => 123, Article.model_type_key => 'WithTemplateAndUniqueID', 'name' => 'my test'})
      doc.class.should eql(WithTemplateAndUniqueID)
    end

  end


  describe "basic saving and retrieving" do
    it "should work fine" do
      @obj.name = "should be easily saved and retrieved"
      @obj.save!
      saved_obj = WithDefaultValues.get!(@obj.id)
      saved_obj.should_not be_nil
    end

    it "should parse the Time attributes automatically" do
      @obj.name = "should parse the Time attributes automatically"
      @obj.set_by_proc.should be_an_instance_of(Time)
      @obj.save
      @obj.set_by_proc.should be_an_instance_of(Time)
      saved_obj = WithDefaultValues.get(@obj.id)
      saved_obj.set_by_proc.should be_an_instance_of(Time)
    end
  end
 
  describe "creating a model" do

    before(:each) do
      @sobj = Basic.new
    end
   
    it "should accept true or false on save for validation" do
      @sobj.should_receive(:valid?)
      @sobj.save(true)
    end

    it "should accept hash with validation option" do
      @sobj.should_receive(:valid?)
      @sobj.save(:validate => true)
    end

    it "should not call validation when option is false" do
      @sobj.should_not_receive(:valid?)
      @sobj.save(false)
    end

    it "should not call validation when option :validate is false" do
      @sobj.should_not_receive(:valid?)
      @sobj.save(:validate => false)
    end

    it "should instantialize and save a document" do
      article = Article.create(:title => 'my test')
      article.title.should == 'my test'
      article.should_not be_new
    end 
    
    it "yields new instance to block before saving (#create)" do
      article = Article.create{|a| a.title = 'my create init block test'}
      article.title.should == 'my create init block test'
      article.should_not be_new
    end 

    it "yields new instance to block before saving (#create!)" do
      article = Article.create{|a| a.title = 'my create bang init block test'}
      article.title.should == 'my create bang init block test'
      article.should_not be_new
    end 

    it "should trigger the create callbacks" do
      doc = WithCallBacks.create(:name => 'my other test') 
      doc.run_before_create.should be_true
      doc.run_after_create.should be_true
      doc.run_before_save.should be_true
      doc.run_after_save.should be_true
    end

  end

  describe "saving a model" do
    before(:all) do
      @sobj = Basic.new
      @sobj.save.should be_true
    end
    
    it "should save the doc" do
      doc = Basic.get(@sobj.id)
      doc['_id'].should == @sobj.id
    end
    
    it "should be set for resaving" do
      rev = @obj.rev
      @sobj['another-key'] = "some value"
      @sobj.save
      @sobj.rev.should_not == rev
    end
    
    it "should set the id" do
      @sobj.id.should be_an_instance_of(String)
    end
    
    it "should set the type" do
      @sobj[@sobj.model_type_key].should == 'Basic'
    end

    it "should accept true or false on save for validation" do
      @sobj.should_receive(:valid?)
      @sobj.save(true)
    end

    it "should accept hash with validation option" do
      @sobj.should_receive(:valid?)
      @sobj.save(:validate => true)
    end

    it "should not call validation when option is false" do
      @sobj.should_not_receive(:valid?)
      @sobj.save(false)
    end

    it "should not call validation when option :validate is false" do
      @sobj.should_not_receive(:valid?)
      @sobj.save(:validate => false)
    end

    describe "save!" do
      
      before(:each) do
        @sobj = Card.new(:first_name => "Marcos", :last_name => "Tapajós")
      end
      
      it "should return true if save the document" do
        @sobj.save!.should be_true
      end
      
      it "should raise error if don't save the document" do
        @sobj.first_name = nil
        lambda { @sobj.save! }.should raise_error(CouchRest::Model::Errors::Validations)
      end

    end
  end
  
  describe "saving a model with a unique_id configured" do
    before(:each) do
      @art = Article.new
      @old = Article.database.get('this-is-the-title') rescue nil
      Article.database.delete_doc(@old) if @old
    end
    
    it "should be a new document" do
      @art.should be_new
      @art.title.should be_nil
    end
    
    it "should require the title" do
      lambda{@art.save}.should raise_error
      @art.title = 'This is the title'
      @art.save.should be_true
    end
    
    it "should not change the slug on update" do
      @art.title = 'This is the title'
      @art.save.should be_true
      @art.title = 'new title'
      @art.save.should be_true
      @art.slug.should == 'this-is-the-title'
    end
    
    it "should raise an error when the slug is taken" do
      @art.title = 'This is the title'
      @art.save.should be_true
      @art2 = Article.new(:title => 'This is the title!')
      lambda{@art2.save}.should raise_error
    end
    
    it "should set the slug" do
      @art.title = 'This is the title'
      @art.save.should be_true
      @art.slug.should == 'this-is-the-title'
    end
    
    it "should set the id" do
      @art.title = 'This is the title'
      @art.save.should be_true
      @art.id.should == 'this-is-the-title'
    end
  end

  describe "saving a model with a unique_id lambda" do
    before(:each) do
      @templated = WithTemplateAndUniqueID.new
      @old = WithTemplateAndUniqueID.get('very-important') rescue nil
      @old.destroy if @old
    end
    
    it "should require the field" do
      lambda{@templated.save}.should raise_error
      @templated['slug'] = 'very-important'
      @templated.save.should be_true
    end
    
    it "should save with the id" do
      @templated['slug'] = 'very-important'
      @templated.save.should be_true
      t = WithTemplateAndUniqueID.get('very-important')
      t.should == @templated
    end
    
    it "should not change the id on update" do
      @templated['slug'] = 'very-important'
      @templated.save.should be_true
      @templated['slug'] = 'not-important'
      @templated.save.should be_true
      t = WithTemplateAndUniqueID.get('very-important')
      t.id.should == @templated.id
    end
    
    it "should raise an error when the id is taken" do
      @templated['slug'] = 'very-important'
      @templated.save.should be_true
      lambda{WithTemplateAndUniqueID.new('slug' => 'very-important').save}.should raise_error
    end
    
    it "should set the id" do
      @templated['slug'] = 'very-important'
      @templated.save.should be_true
      @templated.id.should == 'very-important'
    end
  end

  describe "destroying an instance" do
    before(:each) do
      @dobj = Event.new
      @dobj.save.should be_true
    end
    it "should return true" do
      result = @dobj.destroy
      result.should be_true
    end
    it "should make it go away" do
      @dobj.destroy
      lambda{Basic.get!(@dobj.id)}.should raise_error(CouchRest::Model::DocumentNotFound)
    end
    it "should freeze the object" do
      @dobj.destroy
      # In Ruby 1.9.2 this raises RuntimeError, in 1.8.7 TypeError, D'OH!
      lambda { @dobj.subject = "Test" }.should raise_error(StandardError)
    end
    it "trying to save after should fail" do
      @dobj.destroy
      lambda { @dobj.save }.should raise_error(StandardError)
      lambda{Basic.get!(@dobj.id)}.should raise_error(CouchRest::Model::DocumentNotFound)
    end
    it "should make destroyed? true" do
      @dobj.destroyed?.should be_false
      @dobj.destroy
      @dobj.destroyed?.should be_true
    end
  end


  describe "getting a model" do
    before(:all) do
      @art = Article.new(:title => 'All About Getting')
      @art.save
    end
    it "should load and instantiate it" do
      foundart = Article.get @art.id
      foundart.title.should == "All About Getting"
    end
    it "should load and instantiate with find" do
      foundart = Article.find @art.id
      foundart.title.should == "All About Getting"
    end
    it "should return nil if `get` is used and the document doesn't exist" do
      foundart = Article.get 'matt aimonetti'
      foundart.should be_nil
    end                     
    it "should return nil if a blank id is requested" do
      Article.get("").should be_nil
    end
    it "should raise an error if `get!` is used and the document doesn't exist" do
      expect{ Article.get!('matt aimonetti') }.to raise_error
    end
    it "should raise an error if `get!` is requested with a blank id" do
      expect{ Article.get!("") }.to raise_error
    end
    it "should raise an error if `find!` is used and the document doesn't exist" do
      expect{ Article.find!('matt aimonetti') }.to raise_error
    end
  end

  describe "getting a model with a subobjects array" do
    before(:all) do
      course_doc = {
        "title" => "Metaphysics 200",
        "questions" => [
          {
            "q" => "Carve the ___ of reality at the ___.",
            "a" => ["beast","joints"]
          },{
            "q" => "Who layed the smack down on Leibniz's Law?",
            "a" => "Willard Van Orman Quine"
          }
        ]
      }
      r = Course.database.save_doc course_doc
      @course = Course.get r['id']
    end
    it "should load the course" do
      @course.title.should == "Metaphysics 200"
    end
    it "should instantiate them as such" do
      @course["questions"][0].a[0].should == "beast"
    end
  end

  describe "callbacks" do
    
    before(:each) do
      @doc = WithCallBacks.new
    end
    
    describe "validation" do
      it "should run before_validation before validating" do
        @doc.run_before_validation.should be_nil
        @doc.should be_valid
        @doc.run_before_validation.should be_true
      end
      it "should run after_validation after validating" do
        @doc.run_after_validation.should be_nil
        @doc.should be_valid
        @doc.run_after_validation.should be_true
      end
    end

    describe "with contextual validation on ”create”" do
      it "should validate only within ”create” context" do
        doc = WithContextualValidationOnCreate.new
        doc.save.should be_false
        doc.name = "Alice"
        doc.save.should be_true

        doc.update_attributes(:name => nil).should be_true
      end
    end

    describe "with contextual validation on ”update”" do
      it "should validate only within ”update” context" do
        doc = WithContextualValidationOnUpdate.new
        doc.save.should be_true

        doc.update_attributes(:name => nil).should be_false
        doc.update_attributes(:name => "Bob").should be_true
      end
    end

    describe "save" do
      it "should run the after filter after saving" do
        @doc.run_after_save.should be_nil
        @doc.save.should be_true
        @doc.run_after_save.should be_true
      end
      it "should run the grouped callbacks before saving" do
        @doc.run_one.should be_nil
        @doc.run_two.should be_nil
        @doc.run_three.should be_nil
        @doc.save.should be_true
        @doc.run_one.should be_true
        @doc.run_two.should be_true
        @doc.run_three.should be_true
      end
      it "should not run conditional callbacks" do
        @doc.run_it = false
        @doc.save.should be_true
        @doc.conditional_one.should be_nil
        @doc.conditional_two.should be_nil
      end
      it "should run conditional callbacks" do
        @doc.run_it = true
        @doc.save.should be_true
        @doc.conditional_one.should be_true
        @doc.conditional_two.should be_true
      end
    end
    describe "create" do
      it "should run the before save filter when creating" do
        @doc.run_before_save.should be_nil
        @doc.create.should_not be_nil
        @doc.run_before_save.should be_true
      end
      it "should run the before create filter" do
        @doc.run_before_create.should be_nil
        @doc.create.should_not be_nil
        @doc.create
        @doc.run_before_create.should be_true
      end
      it "should run the after create filter" do
        @doc.run_after_create.should be_nil
        @doc.create.should_not be_nil
        @doc.create
        @doc.run_after_create.should be_true
      end
    end
    describe "update" do
      
      before(:each) do
        @doc.save
      end      
      it "should run the before update filter when updating an existing document" do
        @doc.run_before_update.should be_nil
        @doc.update
        @doc.run_before_update.should be_true
      end
      it "should run the after update filter when updating an existing document" do
        @doc.run_after_update.should be_nil
        @doc.update
        @doc.run_after_update.should be_true
      end
      it "should run the before update filter when saving an existing document" do
        @doc.run_before_update.should be_nil
        @doc.save
        @doc.run_before_update.should be_true
      end
      
    end
  end


  describe "#reload" do
    it "reloads defined attributes" do
      i = Article.create!(:title => "Reload when changed")
      i.title.should == "Reload when changed"

      i.title = "..."
      i.title.should == "..."

      i.reload
      i.title.should == "Reload when changed"
    end

    it "reloads defined attributes set to nil" do
      i = Article.create!(:title => "Reload when nil")
      i.title.should == "Reload when nil"

      i.title = nil
      i.title.should be_nil

      i.reload
      i.title.should == "Reload when nil"
    end

    it "returns self" do
      i = Article.create!(:title => "Reload return self")
      i.reload.should be(i)
    end
  end

  describe ".model_type_value" do
    it "should always return string value of class" do
      Article.model_type_value.should eql('Article')
    end

    describe "usage" do
      let :klass do
        Class.new(CouchRest::Model::Base) do
          property :name, String
          def self.model_type_value
            'something_else'
          end
        end
      end
      it "should use the model type value if overridden" do
        obj = klass.build_from_database(
          '_id' => '1234', 'type' => 'something_else', 'name' => 'Test'
        )
        obj['type'].should eql('something_else')
        obj.name.should eql('Test')
      end
      it "should fail if different model type value provided" do
        expect {
          obj = klass.build_from_database(
            '_id' => '1234', 'type' => 'something', 'name' => 'Test'
          )
        }.to raise_error(NameError)
      end

    end
  end

end
