# encoding: utf-8
require "spec_helper"

describe CouchRest::Model::Properties do

  context "general functionality" do

    before(:each) do
      reset_test_db!
      @card = Card.new(:first_name => "matt")
    end

    it "should be accessible from the object" do
      @card.properties.should be_an_instance_of(Array)
      @card.properties.map{|p| p.name}.should include("first_name")
    end

    it "should list object properties with values" do
      expect(@card.attributes).to be_an_instance_of(Hash)
      expect(@card.read_attributes).to be_an_instance_of(Hash)
      expect(@card.attributes["first_name"]).to eql("matt")
    end

    it "should let you access a property value (getter)" do
      expect(@card.first_name).to eql("matt")
    end

    it "should let you set a property value (setter)" do
      @card.last_name = "Aimonetti"
      @card.last_name.should == "Aimonetti"
    end

    it "should not let you set a property value if it's read only" do
      lambda{@card.read_only_value = "test"}.should raise_error
    end

    it "should let you use an alias for an attribute" do
      @card.last_name = "Aimonetti"
      @card.family_name.should == "Aimonetti"
      @card.family_name.should == @card.last_name
    end

    it "should let you use an alias for a casted attribute" do
      @card.cast_alias = Person.new(:name => ["Aimonetti"])
      @card.cast_alias.name.should == ["Aimonetti"]
      @card.calias.name.should == ["Aimonetti"]
      card = Card.new(:first_name => "matt", :cast_alias => {:name => ["Aimonetti"]})
      card.cast_alias.name.should == ["Aimonetti"]
      card.calias.name.should == ["Aimonetti"]
    end

    it "should raise error if property name coincides with model type key" do
      lambda { Cat.property(Cat.model_type_key) }.should raise_error(/already used/)
    end

    it "should not raise error if property name coincides with model type key on non-model" do
      lambda { Person.property(Article.model_type_key) }.should_not raise_error
    end

    it "should be auto timestamped" do
      @card.created_at.should be_nil
      @card.updated_at.should be_nil
      @card.save.should be_true
      @card.created_at.should_not be_nil
      @card.updated_at.should_not be_nil
    end

    describe "#as_couch_json" do

      it "should provide a simple hash from model" do
        @card.as_couch_json.class.should eql(Hash)
      end

      it "should remove properties from Hash if value is nil" do
        @card.last_name = nil
        @card.as_couch_json.keys.include?('last_name').should be_false
      end

    end

    describe "#as_json" do

      it "should provide a simple hash from model" do
        @card.as_json.class.should eql(Hash)
      end

      it "should pass options to Active Support's as_json" do
        @card.last_name = "Aimonetti"
        @card.as_json(:only => 'last_name').should eql('last_name' => 'Aimonetti')
      end

    end

    describe '#read_attribute' do
      it "should let you use read_attribute method" do
        @card.last_name = "Aimonetti"
        @card.read_attribute(:last_name).should eql('Aimonetti')
        @card.read_attribute('last_name').should eql('Aimonetti')
        last_name_prop = @card.properties.find{|p| p.name == 'last_name'}
        @card.read_attribute(last_name_prop).should eql('Aimonetti')
      end

      it 'should raise an error if the property does not exist' do
        expect { @card.read_attribute(:this_property_should_not_exist) }.to raise_error(ArgumentError)
      end
    end

    describe '#write_attribute' do
      it "should let you use write_attribute method" do
        @card.write_attribute(:last_name, 'Aimonetti 1')
        @card.last_name.should eql('Aimonetti 1')
        @card.write_attribute('last_name', 'Aimonetti 2')
        @card.last_name.should eql('Aimonetti 2')
        last_name_prop = @card.properties.find{|p| p.name == 'last_name'}
        @card.write_attribute(last_name_prop, 'Aimonetti 3')
        @card.last_name.should eql('Aimonetti 3')
      end

      it 'should raise an error if the property does not exist' do
        expect { @card.write_attribute(:this_property_should_not_exist, 823) }.to raise_error(ArgumentError)
      end

      it "should let you use write_attribute on readonly properties" do
        lambda {
          @card.read_only_value = "foo"
        }.should raise_error
        @card.write_attribute(:read_only_value, "foo")
        @card.read_only_value.should == 'foo'
      end

      it "should cast via write_attribute" do
        @card.write_attribute(:cast_alias, {:name => ["Sam", "Lown"]})
        @card.cast_alias.class.should eql(Person)
        @card.cast_alias.name.last.should eql("Lown")
      end

      it "should not cast via write_attribute if property not casted" do
        @card.write_attribute(:first_name, {:name => "Sam"})
        @card.first_name.class.should eql(Hash)
        @card.first_name[:name].should eql("Sam")
      end
    end

    # These tests are light as functionality is covered elsewhere
    describe "#write_attributes" do
      
      let :obj do
        Card.new(:first_name => "matt")
      end

      it "should update attributes" do
        obj.write_attributes( :last_name => 'foo' )
        expect(obj.last_name).to eql('foo')
      end

      it "should not update protected attributes" do
        obj.write_attributes(:bg_color => '#000000')
        expect(obj.bg_color).to_not eql('#000000')
      end

      it "should not update read_only attributes" do
        obj.write_attributes(:read_only_value => 'bar')
        expect(obj.read_only_value).to_not eql('bar')
      end

      it "should have an #attributes= alias" do
        expect {
          obj.attributes = { :last_name => 'foo' }
        }.to_not raise_error
      end

    end

    # These tests are light as functionality is covered elsewhere
    describe "#write_all_attributes" do
      
      let :obj do
        Card.new(:first_name => "matt")
      end

      it "should set regular properties" do
        obj.write_all_attributes(:last_name => 'foo')
        expect(obj.last_name).to eql('foo')
      end

      it "should set read-only and protected properties" do
        obj.write_all_attributes(
          :read_only_value => 'foo',
          :bg_color => '#111111'
        )
        expect(obj.read_only_value).to eql('foo')
        expect(obj.bg_color).to eql('#111111')
      end

    end


    describe "mass updating attributes without property" do
      
      describe "when mass_assign_any_attribute false" do
        
        it "should not allow them to be set" do
          @card.attributes = {:test => 'fooobar'}
          @card['test'].should be_nil
        end

       it 'should not allow them to be updated with update_attributes' do
         @card.update_attributes(:test => 'fooobar')
         @card['test'].should be_nil
       end

       it 'should not have a different revision after update_attributes' do
         @card.save
         rev = @card.rev
         @card.update_attributes(:test => 'fooobar')
         @card.rev.should eql(rev)
       end

       it 'should not have a different revision after save' do
         @card.save
         rev = @card.rev
         @card.attributes = {:test => 'fooobar'}
         @card.save
         @card.rev.should eql(rev)
       end

      end

      describe "when mass_assign_any_attribute true" do
        before(:each) do
          # dup Card class so that no other tests are effected
          card_class = Card.dup
          card_class.class_eval do
            mass_assign_any_attribute true
          end
          @card = card_class.new(:first_name => 'Sam')
        end

        it 'should allow them to be updated' do
          @card.attributes = {:testing => 'fooobar'}
          @card['testing'].should eql('fooobar')
        end

        it 'should allow them to be updated with update_attributes' do
          @card.update_attributes(:testing => 'fooobar')
          @card['testing'].should eql('fooobar')
        end

        it 'should have a different revision after update_attributes' do
          @card.save
          rev = @card.rev
          @card.update_attributes(:testing => 'fooobar')
          @card.rev.should_not eql(rev)
        end

        it 'should have a different revision after save' do
          @card.save
          rev = @card.rev
          @card.attributes = {:testing => 'fooobar'}
          @card.save
          @card.rev.should_not eql(rev)
        end

      end
    end

    describe "mass assignment protection" do

      it "should not store protected attribute using mass assignment" do
        cat_toy = CatToy.new(:name => "Zorro")
        cat = Cat.create(:name => "Helena", :toys => [cat_toy], :favorite_toy => cat_toy, :number => 1)
        cat.number.should be_nil
        cat.number = 1
        cat.save
        cat.number.should == 1
      end

      it "should not store protected attribute when 'declare accessible poperties, assume all the rest are protected'" do
        user = User.create(:name => "Marcos Tapajós", :admin => true)
        user.admin.should be_nil
      end

      it "should not store protected attribute when 'declare protected properties, assume all the rest are accessible'" do
        user = SpecialUser.create(:name => "Marcos Tapajós", :admin => true)
        user.admin.should be_nil
      end

    end

    describe "validation" do
      before(:each) do
        @invoice = Invoice.new(:client_name => "matt", :employee_name => "Chris", :location => "San Diego, CA")
      end

      it "should be able to be validated" do
        @card.valid?.should == true
      end

      it "should let you validate the presence of an attribute" do
        @card.first_name = nil
        @card.should_not be_valid
        @card.errors.should_not be_empty
        @card.errors[:first_name].should == ["can't be blank"]
      end

      it "should let you look up errors for a field by a string name" do
        @card.first_name = nil
        @card.should_not be_valid
        @card.errors['first_name'].should == ["can't be blank"]
      end

      it "should validate the presence of 2 attributes" do
        @invoice.clear
        @invoice.should_not be_valid
        @invoice.errors.should_not be_empty
        @invoice.errors[:client_name].should == ["can't be blank"]
        @invoice.errors[:employee_name].should_not be_empty
      end

      it "should let you set an error message" do
        @invoice.location = nil
        @invoice.valid?
        @invoice.errors[:location].should == ["Hey stupid!, you forgot the location"]
      end

      it "should validate before saving" do
        @invoice.location = nil
        @invoice.should_not be_valid
        @invoice.save.should be_false
        @invoice.should be_new
      end
    end

  end

  context "casting" do

    describe "properties of hash of casted models" do
      it "should be able to assign a casted hash to a hash property" do
        chain = KeyChain.new
        keys = {"House" => "8==$", "Office" => "<>==U"}
        chain.keys = keys
        chain.keys = chain.keys
        chain.keys.should == keys
      end
    end

    describe "properties of array of casted models" do

      before(:each) do
        @course = Course.new :title => 'Test Course'
      end

      it "should allow attribute to be set from an array of objects" do
        @course.questions = [Question.new(:q => "works?"), Question.new(:q => "Meaning of Life?")]
        @course.questions.length.should eql(2)
      end

      it "should allow attribute to be set from an array of hashes" do
        @course.questions = [{:q => "works?"}, {:q => "Meaning of Life?"}]
        @course.questions.length.should eql(2)
        @course.questions.last.q.should eql("Meaning of Life?")
        @course.questions.last.class.should eql(Question) # typecasting
      end

      it "should allow attribute to be set from hash with ordered keys and objects" do
        @course.questions = { '0' => Question.new(:q => "Test1"), '1' => Question.new(:q => 'Test2') }
        @course.questions.length.should eql(2)
        @course.questions.last.q.should eql('Test2')
        @course.questions.last.class.should eql(Question)
      end

      it "should allow attribute to be set from hash with ordered keys and sub-hashes" do
        @course.questions = { '10' => {:q => 'Test10'}, '0' => {:q => "Test1"}, '1' => {:q => 'Test2'} }
        @course.questions.length.should eql(3)
        @course.questions.last.q.should eql('Test10')
        @course.questions.last.class.should eql(Question)
      end

      it "should allow attribute to be set from hash with ordered keys and HashWithIndifferentAccess" do
        # This is similar to what you'd find in an HTML POST parameters
        hash = HashWithIndifferentAccess.new({ '0' => {:q => "Test1"}, '1' => {:q => 'Test2'} })
        @course.questions = hash
        @course.questions.length.should eql(2)
        @course.questions.last.q.should eql('Test2')
        @course.questions.last.class.should eql(Question)
      end

      it "should allow attribute to be set from Hash subclass with ordered keys" do
        ourhash = Class.new(HashWithIndifferentAccess)
        hash = ourhash.new({ '0' => {:q => "Test1"}, '1' => {:q => 'Test2'} })
        @course.questions = hash
        @course.questions.length.should eql(2)
        @course.questions.last.q.should eql('Test2')
        @course.questions.last.class.should eql(Question)
      end

      it "should raise an error if attempting to set single value for array type" do
        lambda {
          @course.questions = Question.new(:q => 'test1')
        }.should raise_error(/Expecting an array/)
      end


    end

    describe "a casted model retrieved from the database" do
      before(:each) do
        reset_test_db!
        @cat = Cat.new(:name => 'Stimpy')
        @cat.favorite_toy = CatToy.new(:name => 'Stinky')
        @cat.toys << CatToy.new(:name => 'Feather')
        @cat.toys << CatToy.new(:name => 'Mouse')
        @cat.save
        @cat = Cat.get(@cat.id)
      end

      describe "as a casted property" do
        it "should already be casted_by its parent" do
          @cat.favorite_toy.casted_by.should === @cat
        end
      end

      describe "from a casted collection" do
        it "should already be casted_by its parent" do
          @cat.toys[0].casted_by.should === @cat
          @cat.toys[1].casted_by.should === @cat
        end
      end
    end

    describe "nested models (not casted)" do
      before(:each) do
        reset_test_db!
        @cat = ChildCat.new(:name => 'Stimpy')
        @cat.mother = {:name => 'Stinky'}
        @cat.siblings = [{:name => 'Feather'}, {:name => 'Felix'}]
        @cat.save
        @cat = ChildCat.get(@cat.id)
      end

      it "should correctly save single relation" do
        @cat.mother.name.should eql('Stinky')
        @cat.mother.casted_by.should eql(@cat)
      end

      it "should correctly save collection" do
        @cat.siblings.first.name.should eql("Feather")
        @cat.siblings.last.casted_by.should eql(@cat)
      end
    end 

  end

  context "multipart attributes" do

    before(:each) do
      @obj = WithDefaultValues.new
    end
 
    context "with valid params" do        
      it "should parse a legal date" do
        valid_date_params = { "exec_date(1i)"=>"2011", 
                              "exec_date(2i)"=>"10", 
                              "exec_date(3i)"=>"18"}
        @obj = WithDateAndTime.new valid_date_params
        @obj.exec_date.should_not be_nil
        @obj.exec_date.should be_kind_of(Date)
        @obj.exec_date.should == Date.new(2011, 10 ,18)
      end
    
      it "should parse a legal time" do
        valid_time_params = { "exec_time(1i)"=>"2011", 
                              "exec_time(2i)"=>"10", 
                              "exec_time(3i)"=>"18",
                              "exec_time(4i)"=>"15",
                              "exec_time(5i)"=>"15",
                              "exec_time(6i)"=>"15",}
        @obj = WithDateAndTime.new valid_time_params
        @obj.exec_time.should_not be_nil
        @obj.exec_time.should be_kind_of(Time)
        @obj.exec_time.should == Time.utc(2011, 10 ,18, 15, 15, 15)
      end
    end
    
    context "with invalid params" do
      before(:each) do
        @invalid_date_params = { "exec_date(1i)"=>"2011", 
                                 "exec_date(2i)"=>"foo", 
                                 "exec_date(3i)"=>"18"}
      end
      it "should still create a model if there are invalid attributes" do
        @obj = WithDateAndTime.new @invalid_date_params
        @obj.should_not be_nil
        @obj.should be_kind_of(WithDateAndTime)
      end
      it "should not crash because of an empty value" do
        @invalid_date_params["exec_date(2i)"] = ""
        @obj = WithDateAndTime.new @invalid_date_params
        @obj.should_not be_nil
        @obj.exec_date.should_not be_kind_of(Date)
        @obj.should be_kind_of(WithDateAndTime)
      end
    end

    # Specific use case for Ruby 2.0.0
    context "with brackets in value" do
      let :klass do
        klass = Class.new(CouchRest::Model::Base)
        klass.class_eval do
          property :name, String
        end
        klass
      end

      it "should be accepted" do
        lambda {
          @obj = klass.new(:name => 'test (object)')
        }.should_not raise_error
      end

    end

  end

end

