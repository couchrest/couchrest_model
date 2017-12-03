# encoding: utf-8
require 'spec_helper'

describe CouchRest::Model::Persistence do

  before(:each) do
    @obj = WithDefaultValues.new
  end

  describe "creating a new document from database" do

    it "should instantialize" do
      doc = Article.build_from_database({'_id' => 'testitem1', '_rev' => 123, 'couchrest-type' => 'Article', 'name' => 'my test'})
      expect(doc.class).to eql(Article)
    end

    it "should instantialize of same class if no couchrest-type included from DB" do
      doc = Article.build_from_database({'_id' => 'testitem1', '_rev' => 123, 'name' => 'my test'})
      expect(doc.class).to eql(Article)
    end

    it "should instantiate document of different type" do
      doc = Article.build_from_database({'_id' => 'testitem2', '_rev' => 123, Article.model_type_key => 'WithTemplateAndUniqueID', 'name' => 'my test'})
      expect(doc.class).to eql(WithTemplateAndUniqueID)
    end

  end


  describe "basic saving and retrieving" do
    it "should work fine" do
      @obj.name = "should be easily saved and retrieved"
      @obj.save!
      saved_obj = WithDefaultValues.get!(@obj.id)
      expect(saved_obj).not_to be_nil
    end

    it "should parse the Time attributes automatically" do
      @obj.name = "should parse the Time attributes automatically"
      expect(@obj.set_by_proc).to be_an_instance_of(Time)
      @obj.save
      expect(@obj.set_by_proc).to be_an_instance_of(Time)
      saved_obj = WithDefaultValues.get(@obj.id)
      expect(saved_obj.set_by_proc).to be_an_instance_of(Time)
    end
  end
 
  describe "creating a model" do

    before(:each) do
      @sobj = Basic.new
    end
   
    it "should accept true or false on save for validation" do
      expect(@sobj).to receive(:valid?)
      @sobj.save(true)
    end

    it "should accept hash with validation option" do
      expect(@sobj).to receive(:valid?)
      @sobj.save(:validate => true)
    end

    it "should not call validation when option is false" do
      expect(@sobj).not_to receive(:valid?)
      @sobj.save(false)
    end

    it "should not call validation when option :validate is false" do
      expect(@sobj).not_to receive(:valid?)
      @sobj.save(:validate => false)
    end

    it "should instantialize and save a document" do
      article = Article.create(:title => 'my test')
      expect(article.title).to eq('my test')
      expect(article).not_to be_new
    end 
    
    it "yields new instance to block before saving (#create)" do
      article = Article.create{|a| a.title = 'my create init block test'}
      expect(article.title).to eq('my create init block test')
      expect(article).not_to be_new
    end 

    it "yields new instance to block before saving (#create!)" do
      article = Article.create{|a| a.title = 'my create bang init block test'}
      expect(article.title).to eq('my create bang init block test')
      expect(article).not_to be_new
    end 

    it "should trigger the create callbacks" do
      doc = WithCallBacks.create(:name => 'my other test') 
      expect(doc.run_before_create).to be_truthy
      expect(doc.run_after_create).to be_truthy
      expect(doc.run_before_save).to be_truthy
      expect(doc.run_after_save).to be_truthy
    end

  end

  describe "saving a model" do
    before(:all) do
      @sobj = Basic.new
      expect(@sobj.save).to be_truthy
    end
    
    it "should save the doc" do
      doc = Basic.get(@sobj.id)
      expect(doc['_id']).to eq(@sobj.id)
    end
    
    it "should be set for resaving" do
      rev = @obj.rev
      @sobj['another-key'] = "some value"
      @sobj.save
      expect(@sobj.rev).not_to eq(rev)
    end
    
    it "should set the id" do
      expect(@sobj.id).to be_an_instance_of(String)
    end
    
    it "should set the type" do
      expect(@sobj[@sobj.model_type_key]).to eq('Basic')
    end

    it "should accept true or false on save for validation" do
      expect(@sobj).to receive(:valid?)
      @sobj.save(true)
    end

    it "should accept hash with validation option" do
      expect(@sobj).to receive(:valid?)
      @sobj.save(:validate => true)
    end

    it "should not call validation when option is false" do
      expect(@sobj).not_to receive(:valid?)
      @sobj.save(false)
    end

    it "should not call validation when option :validate is false" do
      expect(@sobj).not_to receive(:valid?)
      @sobj.save(:validate => false)
    end

    describe "save!" do
      
      before(:each) do
        @sobj = Card.new(:first_name => "Marcos", :last_name => "Tapajós")
      end
      
      it "should return true if save the document" do
        expect(@sobj.save!).to be_truthy
      end
      
      it "should raise error if don't save the document" do
        @sobj.first_name = nil
        expect { @sobj.save! }.to raise_error(CouchRest::Model::Errors::Validations)
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
      expect(@art).to be_new
      expect(@art.title).to be_nil
    end
    
    it "should require the title" do
      expect{@art.save}.to raise_error(/unique_id cannot be nil/)
      @art.title = 'This is the title'
      expect(@art.save).to be_truthy
    end
    
    it "should not change the slug on update" do
      @art.title = 'This is the title'
      expect(@art.save).to be_truthy
      @art.title = 'new title'
      expect(@art.save).to be_truthy
      expect(@art.slug).to eq('this-is-the-title')
    end
    
    it "should raise an error when the slug is taken" do
      @art.title = 'This is the title'
      expect(@art.save).to be_truthy
      @art2 = Article.new(:title => 'This is the title!')
      expect{@art2.save}.to raise_error(/409 Conflict/)
    end
    
    it "should set the slug" do
      @art.title = 'This is the title'
      expect(@art.save).to be_truthy
      expect(@art.slug).to eq('this-is-the-title')
    end
    
    it "should set the id" do
      @art.title = 'This is the title'
      expect(@art.save).to be_truthy
      expect(@art.id).to eq('this-is-the-title')
    end
  end

  describe "saving a model with a unique_id lambda" do
    before(:each) do
      @templated = WithTemplateAndUniqueID.new
      @old = WithTemplateAndUniqueID.get('very-important') rescue nil
      @old.destroy if @old
    end
    
    it "should require the field" do
      expect{@templated.save}.to raise_error(/unique_id cannot be nil/)
      @templated['slug'] = 'very-important'
      expect(@templated.save).to be_truthy
    end
    
    it "should save with the id" do
      @templated['slug'] = 'very-important'
      expect(@templated.save).to be_truthy
      t = WithTemplateAndUniqueID.get('very-important')
      expect(t).to eq(@templated)
    end
    
    it "should not change the id on update" do
      @templated['slug'] = 'very-important'
      expect(@templated.save).to be_truthy
      @templated['slug'] = 'not-important'
      expect(@templated.save).to be_truthy
      t = WithTemplateAndUniqueID.get('very-important')
      expect(t.id).to eq(@templated.id)
    end
    
    it "should raise an error when the id is taken" do
      @templated['slug'] = 'very-important'
      expect(@templated.save).to be_truthy
      expect{WithTemplateAndUniqueID.new('slug' => 'very-important').save}.to raise_error(/409 Conflict/)
    end
    
    it "should set the id" do
      @templated['slug'] = 'very-important'
      expect(@templated.save).to be_truthy
      expect(@templated.id).to eq('very-important')
    end
  end

  describe "destroying an instance" do
    before(:each) do
      @dobj = Event.new
      expect(@dobj.save).to be_truthy
    end
    it "should return true" do
      result = @dobj.destroy
      expect(result).to be_truthy
    end
    it "should make it go away" do
      @dobj.destroy
      expect(Basic.get(@dobj.id)).to be_nil
    end
    it "should freeze the object" do
      @dobj.destroy
      # In Ruby 1.9.2 this raises RuntimeError, in 1.8.7 TypeError, D'OH!
      expect { @dobj.subject = "Test" }.to raise_error(StandardError)
    end
    it "trying to save after should fail" do
      @dobj.destroy
      expect { @dobj.save }.to raise_error(StandardError)
      expect(Basic.get(@dobj.id)).to be_nil
    end
    it "should make destroyed? true" do
      expect(@dobj.destroyed?).to be_falsey
      @dobj.destroy
      expect(@dobj.destroyed?).to be_truthy
    end
  end


  describe "getting a model" do
    before(:all) do
      @art = Article.new(:title => 'All About Getting')
      @art.save
    end
    it "should load and instantiate it" do
      foundart = Article.get @art.id
      expect(foundart.title).to eq("All About Getting")
    end
    it "should load and instantiate with find" do
      foundart = Article.find @art.id
      expect(foundart.title).to eq("All About Getting")
    end
    it "should return nil if `get` is used and the document doesn't exist" do
      foundart = Article.get 'matt aimonetti'
      expect(foundart).to be_nil
    end                     
    it "should return nil if a blank id is requested" do
      expect(Article.get("")).to be_nil
    end
    it "should raise an error if `get!` is used and the document doesn't exist" do
      expect{ Article.get!('matt aimonetti') }.to raise_error(CouchRest::Model::DocumentNotFound)
    end
    it "should raise an error if `get!` is requested with a blank id" do
      expect{ Article.get!("") }.to raise_error(CouchRest::Model::DocumentNotFound)
    end
    it "should raise an error if `find!` is used and the document doesn't exist" do
      expect{ Article.find!('matt aimonetti') }.to raise_error(CouchRest::Model::DocumentNotFound)
    end
    context "without a database" do
      it "should cause #get to raise an error" do
        allow(Article).to receive(:database).and_return(nil)
        expect{ Article.get('foo') }.to raise_error(CouchRest::Model::DatabaseNotDefined)
        expect{ Article.get!('foo') }.to raise_error(CouchRest::Model::DatabaseNotDefined)
      end

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
      expect(@course.title).to eq("Metaphysics 200")
    end
    it "should instantiate them as such" do
      expect(@course["questions"][0].a[0]).to eq("beast")
    end
  end

  describe "callbacks" do
    
    before(:each) do
      @doc = WithCallBacks.new
    end
    
    describe "validation" do
      it "should run before_validation before validating" do
        expect(@doc.run_before_validation).to be_nil
        expect(@doc).to be_valid
        expect(@doc.run_before_validation).to be_truthy
      end
      it "should run after_validation after validating" do
        expect(@doc.run_after_validation).to be_nil
        expect(@doc).to be_valid
        expect(@doc.run_after_validation).to be_truthy
      end
    end

    describe "with contextual validation on ”create”" do
      it "should validate only within ”create” context" do
        doc = WithContextualValidationOnCreate.new
        expect(doc.save).to be_falsey
        doc.name = "Alice"
        expect(doc.save).to be_truthy

        expect(doc.update_attributes(:name => nil)).to be_truthy
      end
    end

    describe "with contextual validation on ”update”" do
      it "should validate only within ”update” context" do
        doc = WithContextualValidationOnUpdate.new
        expect(doc.save).to be_truthy

        expect(doc.update_attributes(:name => nil)).to be_falsey
        expect(doc.update_attributes(:name => "Bob")).to be_truthy
      end
    end

    describe "save" do
      it "should run the after filter after saving" do
        expect(@doc.run_after_save).to be_nil
        expect(@doc.save).to be_truthy
        expect(@doc.run_after_save).to be_truthy
      end
      it "should run the grouped callbacks before saving" do
        expect(@doc.run_one).to be_nil
        expect(@doc.run_two).to be_nil
        expect(@doc.run_three).to be_nil
        expect(@doc.save).to be_truthy
        expect(@doc.run_one).to be_truthy
        expect(@doc.run_two).to be_truthy
        expect(@doc.run_three).to be_truthy
      end
      it "should not run conditional callbacks" do
        @doc.run_it = false
        expect(@doc.save).to be_truthy
        expect(@doc.conditional_one).to be_nil
        expect(@doc.conditional_two).to be_nil
      end
      it "should run conditional callbacks" do
        @doc.run_it = true
        expect(@doc.save).to be_truthy
        expect(@doc.conditional_one).to be_truthy
        expect(@doc.conditional_two).to be_truthy
      end
    end
    describe "create" do
      it "should run the before save filter when creating" do
        expect(@doc.run_before_save).to be_nil
        expect(@doc.create).not_to be_nil
        expect(@doc.run_before_save).to be_truthy
      end
      it "should run the before create filter" do
        expect(@doc.run_before_create).to be_nil
        expect(@doc.create).not_to be_nil
        @doc.create
        expect(@doc.run_before_create).to be_truthy
      end
      it "should run the after create filter" do
        expect(@doc.run_after_create).to be_nil
        expect(@doc.create).not_to be_nil
        @doc.create
        expect(@doc.run_after_create).to be_truthy
      end
    end
    describe "update" do
      
      before(:each) do
        @doc.save
      end      
      it "should run the before update filter when updating an existing document" do
        expect(@doc.run_before_update).to be_nil
        @doc.update
        expect(@doc.run_before_update).to be_truthy
      end
      it "should run the after update filter when updating an existing document" do
        expect(@doc.run_after_update).to be_nil
        @doc.update
        expect(@doc.run_after_update).to be_truthy
      end
      it "should run the before update filter when saving an existing document" do
        expect(@doc.run_before_update).to be_nil
        @doc.save
        expect(@doc.run_before_update).to be_truthy
      end
      
    end
  end


  describe "#reload" do
    it "reloads defined attributes" do
      i = Article.create!(:title => "Reload when changed")
      expect(i.title).to eq("Reload when changed")

      i.title = "..."
      expect(i.title).to eq("...")

      i.reload
      expect(i.title).to eq("Reload when changed")
    end

    it "reloads defined attributes set to nil" do
      i = Article.create!(:title => "Reload when nil")
      expect(i.title).to eq("Reload when nil")

      i.title = nil
      expect(i.title).to be_nil

      i.reload
      expect(i.title).to eq("Reload when nil")
    end

    it "returns self" do
      i = Article.create!(:title => "Reload return self")
      expect(i.reload).to be(i)
    end

    it "should raise DocumentNotFound if doc has been deleted" do
      i = Article.create!(:title => "Reload deleted")
      dup = Article.find(i.id)
      dup.destroy
      expect { i.reload }.to raise_error(CouchRest::Model::DocumentNotFound)
    end
  end

  describe ".model_type_value" do
    it "should always return string value of class" do
      expect(Article.model_type_value).to eql('Article')
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
        expect(obj['type']).to eql('something_else')
        expect(obj.name).to eql('Test')
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
