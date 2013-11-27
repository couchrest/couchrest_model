# encoding: utf-8
require "spec_helper"

describe "Model Base" do
  
  before(:each) do
    @obj = WithDefaultValues.new
  end
  
  describe "instance database connection" do
    it "should use the default database" do
      @obj.database.name.should == 'couchrest-model-test'
    end
    
    it "should override the default db" do
      @obj.database = TEST_SERVER.database!('couchrest-extendedmodel-test')
      @obj.database.name.should == 'couchrest-extendedmodel-test'
      @obj.database.delete!
    end
  end
  
  describe "a new model" do
    it "should be a new document" do
      @obj = Basic.new
      @obj.rev.should be_nil
      @obj.should be_new
      @obj.should be_new_document
      @obj.should be_new_record
    end

    it "should not fail with nil argument" do
      @obj = Basic.new(nil)
      @obj.should_not be_nil
    end

    it "should allow the database to be set" do
      @obj = Basic.new(nil, :database => 'database')
      @obj.database.should eql('database')
    end

    it "should support initialization block" do 
      @obj = Basic.new {|b| b.database = 'database'}
      @obj.database.should eql('database')
    end

    it "should only set defined properties" do
      @doc = WithDefaultValues.new(:name => 'test', :foo => 'bar')
      @doc['name'].should eql('test')
      @doc['foo'].should be_nil
    end

    it "should set all properties with :directly_set_attributes option" do
      @doc = WithDefaultValues.new({:name => 'test', :foo => 'bar'}, :directly_set_attributes => true)
      @doc['name'].should eql('test')
      @doc['foo'].should eql('bar')
    end

    it "should set the model type" do
      @doc = WithDefaultValues.new()
      @doc[WithDefaultValues.model_type_key].should eql('WithDefaultValues')
    end

    it "should call after_initialize method if available" do
      @doc = WithAfterInitializeMethod.new
      @doc['some_value'].should eql('value')
    end

    it "should call after_initialize after block" do
      @doc = WithAfterInitializeMethod.new {|d| d.some_value = "foo"}
      @doc['some_value'].should eql('foo')
    end

    it "should call after_initialize callback if available" do
      klass = Class.new(CouchRest::Model::Base)
      klass.class_eval do # for ruby 1.8.7
        property :name
        after_initialize :set_name
        def set_name; self.name = "foobar"; end
      end
      @doc = klass.new
      @doc.name.should eql("foobar")
    end
  end

  describe "ActiveModel compatability Basic" do

    before(:each) do 
      @obj = Basic.new(nil)
    end

    describe "#to_key" do
      context "when the document is new" do
        it "returns nil" do
          @obj.to_key.should be_nil
        end
      end

      context "when the document is not new" do
        it "returns id in an array" do
          @obj.save
          @obj.to_key.should eql([@obj['_id']])
        end
      end
    end

    describe "#to_param" do
      context "when the document is new" do
        it "returns nil" do
          @obj.to_param.should be_nil
        end
      end

      context "when the document is not new" do
        it "returns id" do
          @obj.save
          @obj.to_param.should eql(@obj['_id'])
        end
      end
    end

    describe "#persisted?" do
      context "when the document is new" do
        it "returns false" do
          @obj.persisted?.should be_false
        end
      end

      context "when the document is not new" do
        it "returns id" do
          @obj.save
          @obj.persisted?.should be_true 
        end
      end
      
      context "when the document is destroyed" do
        it "returns false" do
          @obj.save
          @obj.destroy
          @obj.persisted?.should be_false
        end
      end
    end

    describe "#model_name" do
      it "returns the name of the model" do
        @obj.class.model_name.should eql('Basic')
        WithDefaultValues.model_name.human.should eql("With default values")
      end
    end

    describe "#destroyed?" do
      it "should be present" do
        @obj.should respond_to(:destroyed?)
      end
      it "should return false with new object" do
        @obj.destroyed?.should be_false
      end
      it "should return true after destroy" do
        @obj.save
        @obj.destroy
        @obj.destroyed?.should be_true
      end
    end
  end

  describe "comparisons" do
    describe "#==" do
      context "on saved document" do
        it "should be true on same document" do
          p = Project.create
          p.should eql(p)
        end
        it "should be true after loading" do
          p = Project.create
          p.should eql(Project.get(p.id))
        end
        it "should not be true if databases do not match" do
          p = Project.create
          p2 = p.dup
          p2.stub!(:database).and_return('other')
          p.should_not eql(p2)
        end
        it "should always be false if one document not saved" do
          p = Project.create(:name => 'test')
          o = Project.new(:name => 'test')
          p.should_not eql(o)
        end
      end
      context "with new documents" do
        it "should be true when attributes match" do
          p = Project.new(:name => 'test')
          o = Project.new(:name => 'test')
          p.should eql(o)
        end
        it "should not be true when attributes don't match" do
          p = Project.new(:name => 'test')
          o = Project.new(:name => 'testing')
          p.should_not eql(o)
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
      @art['title'].should == "big bad danger"
      @art.update_attributes_without_saving('date' => Time.now, :title => "super danger")
      @art['title'].should == "super danger"
    end
    it "should silently ignore _id" do
      @art.update_attributes_without_saving('_id' => 'foobar')
      @art['_id'].should_not == 'foobar'
    end
    it "should silently ignore _rev" do
      @art.update_attributes_without_saving('_rev' => 'foobar')
      @art['_rev'].should_not == 'foobar'
    end
    it "should silently ignore created_at" do
      @art.update_attributes_without_saving('created_at' => 'foobar')
      @art['created_at'].should_not == 'foobar'
    end
    it "should silently ignore updated_at" do
      @art.update_attributes_without_saving('updated_at' => 'foobar')
      @art['updated_at'].should_not == 'foobar'
    end
    it "should also work using attributes= alias" do
      @art.respond_to?(:attributes=).should be_true
      @art.attributes = {'date' => Time.now, :title => "something else"}
      @art['title'].should == "something else"
    end
    
    it "should not flip out if an attribute= method is missing and ignore it" do
      lambda {
        @art.update_attributes_without_saving('slug' => "new-slug", :title => "super danger")
      }.should_not raise_error
      @art.slug.should == "big-bad-danger"
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
      @art['title'].should == "big bad danger"
      @art.update_attributes('date' => Time.now, :title => "super danger")
      loaded = Article.get(@art.id)
      loaded['title'].should == "super danger"
    end
  end

  describe "with default" do
    it "should have the default value set at initalization" do
      @obj.preset.should == {:right => 10, :top_align => false}
    end

    it "should have the default false value explicitly assigned" do
      @obj.default_false.should == false
    end
    
    it "should automatically call a proc default at initialization" do
      @obj.set_by_proc.should be_an_instance_of(Time)
      @obj.set_by_proc.should == @obj.set_by_proc
      @obj.set_by_proc.should < Time.now
    end
    
    it "should let you overwrite the default values" do
      obj = WithDefaultValues.new(:preset => 'test')
      obj.preset = 'test'
    end

    it "should keep default values for new instances" do
      obj = WithDefaultValues.new
      obj.preset[:alpha] = 123
      obj.preset.should == {:right => 10, :top_align => false, :alpha => 123}
      another = WithDefaultValues.new
      another.preset.should == {:right => 10, :top_align => false}
    end
    
    it "should work with a default empty array" do
      obj = WithDefaultValues.new(:tags => ['spec'])
      obj.tags.should == ['spec']
    end
    
    it "should set default value of read-only property" do
      obj = WithDefaultValues.new
      obj.read_only_with_default.should == 'generic'
    end
  end

  describe "simplified way of setting property types" do
    it "should set defaults" do
      obj = WithSimplePropertyType.new
      obj.preset.should eql('none')
    end

    it "should handle arrays" do
      obj = WithSimplePropertyType.new(:tags => ['spec'])
      obj.tags.should == ['spec']
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
      @tmpl.preset.should == 'value'
    end
    it "shouldn't override explicitly set values" do
      @tmpl2.preset.should == 'not_value'
    end
    it "shouldn't override existing documents" do
      @tmpl2.save
      tmpl2_reloaded = WithTemplateAndUniqueID.get(@tmpl2.id)
      @tmpl2.preset.should == 'not_value'
      tmpl2_reloaded.preset.should == 'not_value'
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
      rs.length.should == 4
    end
  end
  
  describe "counting all instances of a model" do
    before(:each) do
      reset_test_db!
    end

    it ".count should return 0 if there are no docuemtns" do
      WithTemplateAndUniqueID.count.should == 0
    end

    it ".count should return the number of documents" do
      WithTemplateAndUniqueID.new('slug' => '1').save
      WithTemplateAndUniqueID.new('slug' => '2').save
      WithTemplateAndUniqueID.new('slug' => '3').save
      WithTemplateAndUniqueID.count.should == 3
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
      rs['slug'].should == "1"
    end
    it "should return nil if no instances are found" do
      WithTemplateAndUniqueID.all.each {|obj| obj.destroy }
      WithTemplateAndUniqueID.first.should be_nil
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
      @course["professor"]["name"][1].should == "Hinchliff"
    end
    it "should instantiate the professor as a person" do
      @course['professor'].last_name.should == "Hinchliff"
    end
    it "should instantiate the ends_at as a Time" do
      @course['ends_at'].should == Time.parse("2008/12/19 13:00:00 +0800")
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
      obj.should be_an_instance_of(WithDefaultValues)
      obj.created_at.should be_an_instance_of(Time)
      obj.updated_at.should be_an_instance_of(Time)
      obj.created_at.to_s.should == @obj.updated_at.to_s
    end
    
    it "should not change created_at on update" do
      2.times do 
        lambda do
          @art.save
        end.should_not change(@art, :created_at)
      end
    end
     
    it "should set the time on create" do
      (Time.now - @art.created_at).should < 2
      foundart = Article.get @art.id
      # Use string for comparison to cope with microsecond differences
      foundart.created_at.to_s.should == foundart.updated_at.to_s
    end
    it "should set the time on update" do
      @art.title = "new title"  # only saved if @art.changed? == true
      @art.save
      @art.created_at.should < @art.updated_at
    end
  end
  
  describe "getter and setter methods" do
    it "should try to call the arg= method before setting :arg in the hash" do
      @doc = WithGetterAndSetterMethods.new(:arg => "foo")
      @doc['arg'].should be_nil
      @doc[:arg].should be_nil
      @doc.other_arg.should == "foo-foo"
    end
  end

 describe "recursive validation on a model" do
    before :each do
      reset_test_db!
      @cat = Cat.new(:name => 'Sockington')
    end
    
    it "should not save if a nested casted model is invalid" do
      @cat.favorite_toy = CatToy.new
      @cat.should_not be_valid
      @cat.save.should be_false
      lambda{@cat.save!}.should raise_error
    end
    
    it "should save when nested casted model is valid" do
      @cat.favorite_toy = CatToy.new(:name => 'Squeaky')
      @cat.should be_valid
      @cat.save.should be_true
      lambda{@cat.save!}.should_not raise_error
    end
    
    it "should not save when nested collection contains an invalid casted model" do
      @cat.toys = [CatToy.new(:name => 'Feather'), CatToy.new]
      @cat.should_not be_valid
      @cat.save.should be_false
      lambda{@cat.save!}.should raise_error
    end
    
    it "should save when nested collection contains valid casted models" do
      @cat.toys = [CatToy.new(:name => 'feather'), CatToy.new(:name => 'ball-o-twine')]
      @cat.should be_valid
      @cat.save.should be_true
      lambda{@cat.save!}.should_not raise_error
    end
    
    it "should not fail if the nested casted model doesn't have validation" do
      Cat.property :trainer, Person
      Cat.validates_presence_of :name
      cat = Cat.new(:name => 'Mr Bigglesworth')
      cat.trainer = Person.new
      cat.should be_valid
      cat.save.should be_true
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
