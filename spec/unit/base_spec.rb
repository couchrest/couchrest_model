# encoding: utf-8
require "spec_helper"

describe "Model Base" do
  
  before(:each) do
    @obj = WithDefaultValues.new
  end
  
  describe "instance database connection" do
    it "should use the default database" do
      expect(@obj.database.name).to eq('couchrest-model-test')
    end
    
    it "should override the default db" do
      @obj.database = TEST_SERVER.database!('couchrest-extendedmodel-test')
      expect(@obj.database.name).to eql 'couchrest-extendedmodel-test'
      @obj.database.delete!
    end
  end
  
  describe "a new model" do
    it "should be a new document" do
      @obj = Basic.new
      expect(@obj.rev).to be_nil
      expect(@obj).to be_new
      expect(@obj).to be_new_document
      expect(@obj).to be_new_record
    end

    it "should not fail with nil argument" do
      @obj = Basic.new(nil)
      expect(@obj).not_to be_nil
    end

    it "should allow the database to be set" do
      @obj = Basic.new(nil, :database => 'database')
      expect(@obj.database).to eql('database')
    end

    it "should support initialization block" do 
      @obj = Basic.new {|b| b.database = 'database'}
      expect(@obj.database).to eql('database')
    end

    it "should only set defined properties" do
      @doc = WithDefaultValues.new(:name => 'test', :foo => 'bar')
      expect(@doc['name']).to eql('test')
      expect(@doc['foo']).to be_nil
    end

    it "should set all properties with :write_all_attributes option" do
      @doc = WithDefaultValues.new({:name => 'test', :foo => 'bar'}, :write_all_attributes => true)
      expect(@doc['name']).to eql('test')
      expect(@doc['foo']).to eql('bar')
    end

    it "should set the model type" do
      @doc = WithDefaultValues.new()
      expect(@doc[WithDefaultValues.model_type_key]).to eql('WithDefaultValues')
    end

    it "should call after_initialize method if available" do
      @doc = WithAfterInitializeMethod.new
      expect(@doc['some_value']).to eql('value')
    end

    it "should call after_initialize after block" do
      @doc = WithAfterInitializeMethod.new {|d| d.some_value = "foo"}
      expect(@doc['some_value']).to eql('foo')
    end

    it "should call after_initialize callback if available" do
      klass = Class.new(CouchRest::Model::Base)
      klass.class_eval do # for ruby 1.8.7
        property :name
        after_initialize :set_name
        def set_name; self.name = "foobar"; end
      end
      @doc = klass.new
      expect(@doc.name).to eql("foobar")
    end
  end

  describe "ActiveModel compatability Basic" do

    before(:each) do 
      @obj = Basic.new(nil)
    end

    describe "#to_key" do
      context "when the document is new" do
        it "returns nil" do
          expect(@obj.to_key).to be_nil
        end
      end

      context "when the document is not new" do
        it "returns id in an array" do
          @obj.save
          expect(@obj.to_key).to eql([@obj['_id']])
        end
      end
    end

    describe "#to_param" do
      context "when the document is new" do
        it "returns nil" do
          expect(@obj.to_param).to be_nil
        end
      end

      context "when the document is not new" do
        it "returns id" do
          @obj.save
          expect(@obj.to_param).to eql(@obj['_id'])
        end
      end
    end

    describe "#persisted?" do
      context "when the document is new" do
        it "returns false" do
          expect(@obj.persisted?).to be_falsey
        end
      end

      context "when the document is not new" do
        it "returns id" do
          @obj.save
          expect(@obj.persisted?).to be_truthy 
        end
      end
      
      context "when the document is destroyed" do
        it "returns false" do
          @obj.save
          @obj.destroy
          expect(@obj.persisted?).to be_falsey
        end
      end
    end

    describe "#model_name" do
      it "returns the name of the model" do
        expect(@obj.class.model_name).to eql('Basic')
        expect(WithDefaultValues.model_name.human).to eql("With default values")
      end
    end

    describe "#destroyed?" do
      it "should be present" do
        expect(@obj).to respond_to(:destroyed?)
      end
      it "should return false with new object" do
        expect(@obj.destroyed?).to be_falsey
      end
      it "should return true after destroy" do
        @obj.save
        @obj.destroy
        expect(@obj.destroyed?).to be_truthy
      end
    end
  end

  describe "comparisons" do
    describe "#==" do
      context "on saved document" do
        it "should be true on same document" do
          p = Project.create
          expect(p).to eql(p)
        end
        it "should be true after loading" do
          p = Project.create
          expect(p).to eql(Project.get(p.id))
        end
        it "should not be true if databases do not match" do
          p = Project.create
          p2 = p.dup
          allow(p2).to receive(:database).and_return('other')
          expect(p).not_to eql(p2)
        end
        it "should always be false if one document not saved" do
          p = Project.create(:name => 'test')
          o = Project.new(:name => 'test')
          expect(p).not_to eql(o)
        end
      end
      context "with new documents" do
        it "should be true when attributes match" do
          p = Project.new(:name => 'test')
          o = Project.new(:name => 'test')
          expect(p).to eql(o)
        end
        it "should not be true when attributes don't match" do
          p = Project.new(:name => 'test')
          o = Project.new(:name => 'testing')
          expect(p).not_to eql(o)
        end
      end
    end
  end

  describe "update attributes without saving" do
    before(:each) do
      a = Article.get "big-bad-danger" rescue nil
      a.destroy if a
      @art = Article.new(:title => "big bad danger")
      @art.save
    end
    it "should work for attribute= methods" do
      expect(@art['title']).to eql("big bad danger")
      @art.write_attributes('date' => Time.now, :title => "super danger")
      expect(@art['title']).to eql("super danger")
    end
    it "should silently ignore _id" do
      @art.write_attributes('_id' => 'foobar')
      expect(@art['_id']).to_not eql('foobar')
    end
    it "should silently ignore _rev" do
      @art.write_attributes('_rev' => 'foobar')
      expect(@art['_rev']).to_not eql('foobar')
    end
    it "should silently ignore created_at" do
      @art.write_attributes('created_at' => 'foobar')
      expect(@art['created_at'].to_s).to_not eql('foobar')
    end
    it "should silently ignore updated_at" do
      @art.write_attributes('updated_at' => 'foobar')
      expect(@art['updated_at']).to_not eql('foobar')
    end
    it "should also work using attributes= alias" do
      expect(@art.respond_to?(:attributes=)).to be_truthy
      @art.attributes = {'date' => Time.now, :title => "something else"}
      expect(@art['title']).to eql("something else")
    end
    
    it "should not flip out if an attribute= method is missing and ignore it" do
      expect {
        @art.attributes = {'slug' => "new-slug", :title => "super danger"}
      }.not_to raise_error
      expect(@art.slug).to eq("big-bad-danger")
    end

    #it "should not change other attributes if there is an error" do
    #  lambda {
    #    @art.update_attributes_without_saving('slug' => "new-slug", :title => "super danger")        
    #  }.should raise_error
    #  @art['title'].should == "big bad danger"
    #end
  end

  describe "update attributes" do
    before(:each) do
      a = Article.get "big-bad-danger" rescue nil
      a.destroy if a
      @art = Article.new(:title => "big bad danger")
      @art.save
    end
    it "should save" do
      expect(@art['title']).to eq("big bad danger")
      @art.update_attributes('date' => Time.now, :title => "super danger")
      loaded = Article.get(@art.id)
      expect(loaded['title']).to eq("super danger")
    end
  end

  describe "with default" do
    it "should have the default value set at initalization" do
      expect(@obj.preset).to eq({:right => 10, :top_align => false})
    end

    it "should have the default false value explicitly assigned" do
      expect(@obj.default_false).to eq(false)
    end
    
    it "should automatically call a proc default at initialization" do
      expect(@obj.set_by_proc).to be_an_instance_of(Time)
      expect(@obj.set_by_proc).to eq(@obj.set_by_proc)
      expect(@obj.set_by_proc.utc).to be < Time.now.utc
    end
    
    it "should let you overwrite the default values" do
      obj = WithDefaultValues.new(:preset => 'test')
      obj.preset = 'test'
    end

    it "should keep default values for new instances" do
      obj = WithDefaultValues.new
      obj.preset[:alpha] = 123
      expect(obj.preset).to eq({:right => 10, :top_align => false, :alpha => 123})
      another = WithDefaultValues.new
      expect(another.preset).to eq({:right => 10, :top_align => false})
    end
    
    it "should work with a default empty array" do
      obj = WithDefaultValues.new(:tags => ['spec'])
      expect(obj.tags).to eq(['spec'])
    end
    
    it "should set default value of read-only property" do
      obj = WithDefaultValues.new
      expect(obj.read_only_with_default).to eq('generic')
    end
  end

  describe "simplified way of setting property types" do
    it "should set defaults" do
      obj = WithSimplePropertyType.new
      expect(obj.preset).to eql('none')
    end

    it "should handle arrays" do
      obj = WithSimplePropertyType.new(:tags => ['spec'])
      expect(obj.tags).to eq(['spec'])
    end
  end
  
  describe "a doc with template values (CR::Model spec)" do
    before(:all) do
      WithTemplateAndUniqueID.all.map{|o| o.destroy}
      WithTemplateAndUniqueID.database.bulk_delete
      @tmpl = WithTemplateAndUniqueID.new
      @tmpl2 = WithTemplateAndUniqueID.new(:preset => 'not_value', 'slug' => '1')
    end
    it "should have fields set when new" do
      expect(@tmpl.preset).to eq('value')
    end
    it "shouldn't override explicitly set values" do
      expect(@tmpl2.preset).to eq('not_value')
    end
    it "shouldn't override existing documents" do
      @tmpl2.save
      tmpl2_reloaded = WithTemplateAndUniqueID.get(@tmpl2.id)
      expect(@tmpl2.preset).to eq('not_value')
      expect(tmpl2_reloaded.preset).to eq('not_value')
    end
  end
  
  
  describe "finding all instances of a model" do
    before(:all) do
      WithTemplateAndUniqueID.all.map{|o| o.destroy}
      WithTemplateAndUniqueID.database.bulk_delete
      WithTemplateAndUniqueID.new('slug' => '1').save
      WithTemplateAndUniqueID.new('slug' => '2').save
      WithTemplateAndUniqueID.new('slug' => '3').save
      WithTemplateAndUniqueID.new('slug' => '4').save
    end
    it "should find all" do
      rs = WithTemplateAndUniqueID.all 
      expect(rs.length).to eq(4)
    end
  end
  
  describe "counting all instances of a model" do
    before(:each) do
      reset_test_db!
    end

    it ".count should return 0 if there are no docuemtns" do
      expect(WithTemplateAndUniqueID.count).to eq(0)
    end

    it ".count should return the number of documents" do
      WithTemplateAndUniqueID.new('slug' => '1').save
      WithTemplateAndUniqueID.new('slug' => '2').save
      WithTemplateAndUniqueID.new('slug' => '3').save
      expect(WithTemplateAndUniqueID.count).to eq(3)
    end
  end
  
  describe "finding the first instance of a model" do
    before(:each) do      
      reset_test_db!
      WithTemplateAndUniqueID.new('slug' => '1').save
      WithTemplateAndUniqueID.new('slug' => '2').save
      WithTemplateAndUniqueID.new('slug' => '3').save
      WithTemplateAndUniqueID.new('slug' => '4').save
    end
    it "should find first" do
      rs = WithTemplateAndUniqueID.first
      expect(rs['slug']).to eq("1")
    end
    it "should return nil if no instances are found" do
      WithTemplateAndUniqueID.all.each {|obj| obj.destroy }
      expect(WithTemplateAndUniqueID.first).to be_nil
    end
  end

  
  describe "getting a model with a subobject field" do
    before(:all) do
      course_doc = {
        "title" => "Metaphysics 410",
        "professor" => {
          "name" => ["Mark", "Hinchliff"]
        },
        "ends_at" => "2008/12/19 13:00:00 +0800"
      }
      r = Course.database.save_doc course_doc
      @course = Course.get r['id']
    end
    it "should load the course" do
      expect(@course["professor"]["name"][1]).to eq("Hinchliff")
    end
    it "should instantiate the professor as a person" do
      expect(@course['professor'].last_name).to eq("Hinchliff")
    end
    it "should instantiate the ends_at as a Time" do
      expect(@course['ends_at']).to eq(Time.parse("2008/12/19 13:00:00 +0800"))
    end
  end
  
  describe "timestamping" do
    before(:each) do
      oldart = Article.get "saving-this" rescue nil
      oldart.destroy if oldart
      @art = Article.new(:title => "Saving this")
      @art.save
    end
    
    it "should define the updated_at and created_at getters and set the values" do
      @obj.save
      json = @obj.to_json
      obj = WithDefaultValues.get(@obj.id)
      expect(obj).to be_an_instance_of(WithDefaultValues)
      expect(obj.created_at).to be_an_instance_of(Time)
      expect(obj.updated_at).to be_an_instance_of(Time)
      expect(obj.created_at.to_s).to eq(@obj.updated_at.to_s)
    end
    
    it "should not change created_at on update" do
      2.times do 
        expect do
          @art.save
        end.not_to change(@art, :created_at)
      end
    end
     
    it "should set the time on create" do
      expect(Time.now - @art.created_at).to be < 2
      foundart = Article.get @art.id
      # Use string for comparison to cope with microsecond differences
      expect(foundart.created_at.to_s).to eq(foundart.updated_at.to_s)
    end
    it "should set the time on update" do
      @art.title = "new title"  # only saved if @art.changed? == true
      @art.save
      expect(@art.created_at).to be < @art.updated_at
    end
  end
  
  describe "getter and setter methods" do
    it "should try to call the arg= method before setting :arg in the hash" do
      @doc = WithGetterAndSetterMethods.new(:arg => "foo")
      expect(@doc['arg']).to be_nil
      expect(@doc[:arg]).to be_nil
      expect(@doc.other_arg).to eq("foo-foo")
    end
  end

 describe "recursive validation on a model" do
    before :each do
      reset_test_db!
      @cat = Cat.new(:name => 'Sockington')
    end
    
    it "should not save if a nested casted model is invalid" do
      @cat.favorite_toy = CatToy.new
      expect(@cat).not_to be_valid
      expect(@cat.save).to be_falsey
      expect{@cat.save!}.to raise_error(/Validation Failed/)
    end
    
    it "should save when nested casted model is valid" do
      @cat.favorite_toy = CatToy.new(:name => 'Squeaky')
      expect(@cat).to be_valid
      expect(@cat.save).to be_truthy
      expect{@cat.save!}.not_to raise_error
    end
    
    it "should not save when nested collection contains an invalid casted model" do
      @cat.toys = [CatToy.new(:name => 'Feather'), CatToy.new]
      expect(@cat).not_to be_valid
      expect(@cat.save).to be_falsey
      expect{@cat.save!}.to raise_error(/Validation Failed/)
    end
    
    it "should save when nested collection contains valid casted models" do
      @cat.toys = [CatToy.new(:name => 'feather'), CatToy.new(:name => 'ball-o-twine')]
      expect(@cat).to be_valid
      expect(@cat.save).to be_truthy
      expect{@cat.save!}.not_to raise_error
    end
    
    it "should not fail if the nested casted model doesn't have validation" do
      Cat.property :trainer, Person
      Cat.validates_presence_of :name
      cat = Cat.new(:name => 'Mr Bigglesworth')
      cat.trainer = Person.new
      expect(cat).to be_valid
      expect(cat.save).to be_truthy
    end
  end

  describe "searching the contents of a model" do
    before :each do
      @db = reset_test_db!

      names = ["Fuzzy", "Whiskers", "Mr Bigglesworth", "Sockington", "Smitty", "Sammy", "Samson", "Simon"]
      names.each { |name| Cat.create(:name => name) }

      search_function = { 'defaults' => {'store' => 'no', 'index' => 'analyzed_no_norms'},
          'index' => "function(doc) { ret = new Document(); ret.add(doc['name'], {'field':'name'}); return ret; }" }
      @db.save_doc({'_id' => '_design/search', 'fulltext' => {'cats' => search_function}})
    end
  end

end
