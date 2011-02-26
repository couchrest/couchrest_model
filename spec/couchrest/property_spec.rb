# encoding: utf-8
require File.expand_path('../../spec_helper', __FILE__)
require File.join(FIXTURE_PATH, 'more', 'cat')
require File.join(FIXTURE_PATH, 'more', 'person')
require File.join(FIXTURE_PATH, 'more', 'card')
require File.join(FIXTURE_PATH, 'more', 'invoice')
require File.join(FIXTURE_PATH, 'more', 'service')
require File.join(FIXTURE_PATH, 'more', 'event')
require File.join(FIXTURE_PATH, 'more', 'user')
require File.join(FIXTURE_PATH, 'more', 'course')


describe "Model properties" do

  before(:each) do
    reset_test_db!
    @card = Card.new(:first_name => "matt")
  end

  it "should be accessible from the object" do
    @card.properties.should be_an_instance_of(Array)
    @card.properties.map{|p| p.name}.should include("first_name")
  end

  it "should list object properties with values" do
    @card.properties_with_values.should be_an_instance_of(Hash)
    @card.properties_with_values["first_name"].should == "matt"
  end

  it "should let you access a property value (getter)" do
    @card.first_name.should == "matt"
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


  it "should be auto timestamped" do
    @card.created_at.should be_nil
    @card.updated_at.should be_nil
    @card.save.should be_true
    @card.created_at.should_not be_nil
    @card.updated_at.should_not be_nil
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

  describe "mass updating attributes without property" do
    
    describe "when mass_assign_any_attribute false" do
      
      it "should not allow them to be set" do
        @card.attributes = {:test => 'fooobar'}
        @card['test'].should be_nil
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
        @card.attributes = {:test => 'fooobar'}
        @card['test'].should eql('fooobar')
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

  describe "casting" do
    before(:each) do
      @course = Course.new(:title => 'Relaxation')
    end

    describe "when value is nil" do
      it "leaves the value unchanged" do
        @course.title = nil
        @course['title'].should == nil
      end
    end

    describe "when type primitive is an Object" do
      it "it should not cast given value" do
        @course.participants = [{}, 'q', 1]
        @course['participants'].should == [{}, 'q', 1]
      end

      it "should cast started_on to Date" do
        @course.started_on = Date.today
        @course['started_on'].should be_an_instance_of(Date)
      end
    end

    describe "when type primitive is a String" do
      it "keeps string value unchanged" do
        value = "1.0"
        @course.title = value
        @course['title'].should equal(value)
      end

      it "it casts to string representation of the value" do
        @course.title = 1.0
        @course['title'].should eql("1.0")
      end
    end

    describe 'when type primitive is a Float' do
      it 'returns same value if a float' do
        value = 24.0
        @course.estimate = value
        @course['estimate'].should equal(value)
      end

      it 'returns float representation of a zero string integer' do
        @course.estimate = '0'
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive string integer' do
        @course.estimate = '24'
        @course['estimate'].should eql(24.0)
      end

      it 'returns float representation of a negative string integer' do
        @course.estimate = '-24'
        @course['estimate'].should eql(-24.0)
      end

      it 'returns float representation of a zero string float' do
        @course.estimate = '0.0'
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive string float' do
        @course.estimate = '24.35'
        @course['estimate'].should eql(24.35)
      end

      it 'returns float representation of a negative string float' do
        @course.estimate = '-24.35'
        @course['estimate'].should eql(-24.35)
      end

      it 'returns float representation of a zero string float, with no leading digits' do
        @course.estimate = '.0'
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive string float, with no leading digits' do
        @course.estimate = '.41'
        @course['estimate'].should eql(0.41)
      end

      it 'returns float representation of a zero integer' do
        @course.estimate = 0
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive integer' do
        @course.estimate = 24
        @course['estimate'].should eql(24.0)
      end

      it 'returns float representation of a negative integer' do
        @course.estimate = -24
        @course['estimate'].should eql(-24.0)
      end

      it 'returns float representation of a zero decimal' do
        @course.estimate = BigDecimal('0.0')
        @course['estimate'].should eql(0.0)
      end

      it 'returns float representation of a positive decimal' do
        @course.estimate = BigDecimal('24.35')
        @course['estimate'].should eql(24.35)
      end

      it 'returns float representation of a negative decimal' do
        @course.estimate = BigDecimal('-24.35')
        @course['estimate'].should eql(-24.35)
      end

      it 'return float of a number with commas instead of points for decimals' do
        @course.estimate = '23,35'
        @course['estimate'].should eql(23.35)
      end

      it "should handle numbers with commas and points" do
        @course.estimate = '1,234.00'
        @course.estimate.should eql(1234.00)
      end

      it "should handle a mis-match of commas and points and maintain the last one" do
        @course.estimate = "1,232.434.123,323"
        @course.estimate.should eql(1232434123.323)
      end

      it "should handle numbers with whitespace" do
        @course.estimate = " 24.35 "
        @course.estimate.should eql(24.35)
      end

      [ Object.new, true, '00.0', '0.', '-.0', 'string' ].each do |value|
        it "does not typecast non-numeric value #{value.inspect}" do
          @course.estimate = value
          @course['estimate'].should equal(value)
        end
      end

    end

    describe 'when type primitive is a Integer' do
      it 'returns same value if an integer' do
        value = 24
        @course.hours = value
        @course['hours'].should equal(value)
      end

      it 'returns integer representation of a zero string integer' do
        @course.hours = '0'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive string integer' do
        @course.hours = '24'
        @course['hours'].should eql(24)
      end

      it 'returns integer representation of a negative string integer' do
        @course.hours = '-24'
        @course['hours'].should eql(-24)
      end

      it 'returns integer representation of a zero string float' do
        @course.hours = '0.0'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive string float' do
        @course.hours = '24.35'
        @course['hours'].should eql(24)
      end

      it 'returns integer representation of a negative string float' do
        @course.hours = '-24.35'
        @course['hours'].should eql(-24)
      end

      it 'returns integer representation of a zero string float, with no leading digits' do
        @course.hours = '.0'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive string float, with no leading digits' do
        @course.hours = '.41'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a zero float' do
        @course.hours = 0.0
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive float' do
        @course.hours = 24.35
        @course['hours'].should eql(24)
      end

      it 'returns integer representation of a negative float' do
        @course.hours = -24.35
        @course['hours'].should eql(-24)
      end

      it 'returns integer representation of a zero decimal' do
        @course.hours = '0.0'
        @course['hours'].should eql(0)
      end

      it 'returns integer representation of a positive decimal' do
        @course.hours = '24.35'
        @course['hours'].should eql(24)
      end

      it 'returns integer representation of a negative decimal' do
        @course.hours = '-24.35'
        @course['hours'].should eql(-24)
      end

      it "should handle numbers with whitespace" do
        @course.hours = " 24 "
        @course['hours'].should eql(24)
      end

      [ Object.new, true, '00.0', '0.', '-.0', 'string' ].each do |value|
        it "does not typecast non-numeric value #{value.inspect}" do
          @course.hours = value
          @course['hours'].should equal(value)
        end
      end
    end

    describe 'when type primitive is a BigDecimal' do
      it 'returns same value if a decimal' do
        value = BigDecimal('24.0')
        @course.profit = value
        @course['profit'].should equal(value)
      end

      it 'returns decimal representation of a zero string integer' do
        @course.profit = '0'
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive string integer' do
        @course.profit = '24'
        @course['profit'].should eql(BigDecimal('24.0'))
      end

      it 'returns decimal representation of a negative string integer' do
        @course.profit = '-24'
        @course['profit'].should eql(BigDecimal('-24.0'))
      end

      it 'returns decimal representation of a zero string float' do
        @course.profit = '0.0'
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive string float' do
        @course.profit = '24.35'
        @course['profit'].should eql(BigDecimal('24.35'))
      end

      it 'returns decimal representation of a negative string float' do
        @course.profit = '-24.35'
        @course['profit'].should eql(BigDecimal('-24.35'))
      end

      it 'returns decimal representation of a zero string float, with no leading digits' do
        @course.profit = '.0'
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive string float, with no leading digits' do
        @course.profit = '.41'
        @course['profit'].should eql(BigDecimal('0.41'))
      end

      it 'returns decimal representation of a zero integer' do
        @course.profit = 0
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive integer' do
        @course.profit = 24
        @course['profit'].should eql(BigDecimal('24.0'))
      end

      it 'returns decimal representation of a negative integer' do
        @course.profit = -24
        @course['profit'].should eql(BigDecimal('-24.0'))
      end

      it 'returns decimal representation of a zero float' do
        @course.profit = 0.0
        @course['profit'].should eql(BigDecimal('0.0'))
      end

      it 'returns decimal representation of a positive float' do
        @course.profit = 24.35
        @course['profit'].should eql(BigDecimal('24.35'))
      end

      it 'returns decimal representation of a negative float' do
        @course.profit = -24.35
        @course['profit'].should eql(BigDecimal('-24.35'))
      end

      it "should handle numbers with whitespace" do
        @course.profit = " 24.35 "
        @course['profit'].should eql(BigDecimal('24.35'))
      end

      [ Object.new, true, '00.0', '0.', '-.0', 'string' ].each do |value|
        it "does not typecast non-numeric value #{value.inspect}" do
          @course.profit = value
          @course['profit'].should equal(value)
        end
      end
    end

    describe 'when type primitive is a DateTime' do
      describe 'and value given as a hash with keys like :year, :month, etc' do
        it 'builds a DateTime instance from hash values' do
          @course.updated_at = {
            :year  => '2006',
            :month => '11',
            :day   => '23',
            :hour  => '12',
            :min   => '0',
            :sec   => '0'
          }
          result = @course['updated_at']

          result.should be_kind_of(DateTime)
          result.year.should eql(2006)
          result.month.should eql(11)
          result.day.should eql(23)
          result.hour.should eql(12)
          result.min.should eql(0)
          result.sec.should eql(0)
        end
      end

      describe 'and value is a string' do
        it 'parses the string' do
          @course.updated_at = 'Dec, 2006'
          @course['updated_at'].month.should == 12
        end
      end

      it 'does not typecast non-datetime values' do
        @course.updated_at = 'not-datetime'
        @course['updated_at'].should eql('not-datetime')
      end
    end

    describe 'when type primitive is a Date' do
      describe 'and value given as a hash with keys like :year, :month, etc' do
        it 'builds a Date instance from hash values' do
          @course.started_on = {
            :year  => '2007',
            :month => '3',
            :day   => '25'
          }
          result = @course['started_on']

          result.should be_kind_of(Date)
          result.year.should eql(2007)
          result.month.should eql(3)
          result.day.should eql(25)
        end
      end

      describe 'and value is a string' do
        it 'parses the string' do
          @course.started_on = 'Dec 20th, 2006'
          @course.started_on.month.should == 12
          @course.started_on.day.should == 20
          @course.started_on.year.should == 2006
        end
      end

      it 'does not typecast non-date values' do
        @course.started_on = 'not-date'
        @course['started_on'].should eql('not-date')
      end
    end

    describe 'when type primitive is a Time' do
      describe 'and value given as a hash with keys like :year, :month, etc' do
        it 'builds a Time instance from hash values' do
          @course.ends_at = {
            :year  => '2006',
            :month => '11',
            :day   => '23',
            :hour  => '12',
            :min   => '0',
            :sec   => '0'
          }
          result = @course['ends_at']

          result.should be_kind_of(Time)
          result.year.should  eql(2006)
          result.month.should eql(11)
          result.day.should   eql(23)
          result.hour.should  eql(12)
          result.min.should   eql(0)
          result.sec.should   eql(0)
        end
      end

      describe 'and value is a string' do
        it 'parses the string' do
          t = Time.now
          @course.ends_at = t.strftime('%Y/%m/%d %H:%M:%S %z')
          @course['ends_at'].year.should  eql(t.year)
          @course['ends_at'].month.should eql(t.month)
          @course['ends_at'].day.should   eql(t.day)
          @course['ends_at'].hour.should  eql(t.hour)
          @course['ends_at'].min.should   eql(t.min)
          @course['ends_at'].sec.should   eql(t.sec)
        end
        it 'parses the string without offset' do
          t = Time.now
          @course.ends_at = t.strftime("%Y-%m-%d %H:%M:%S")
          @course['ends_at'].year.should  eql(t.year)
          @course['ends_at'].month.should eql(t.month)
          @course['ends_at'].day.should   eql(t.day)
          @course['ends_at'].hour.should  eql(t.hour)
          @course['ends_at'].min.should   eql(t.min)
          @course['ends_at'].sec.should   eql(t.sec)
        end
      end

      it 'does not typecast non-time values' do
        @course.ends_at = 'not-time'
        @course['ends_at'].should eql('not-time')
      end
    end

    describe 'when type primitive is a Class' do
      it 'returns same value if a class' do
        value = Course
        @course.klass = value
        @course['klass'].should equal(value)
      end

      it 'returns the class if found' do
        @course.klass = 'Course'
        @course['klass'].should eql(Course)
      end

      it 'does not typecast non-class values' do
        @course.klass = 'NoClass'
        @course['klass'].should eql('NoClass')
      end
    end

    describe 'when type primitive is a Boolean' do

      [ true, 'true', 'TRUE', '1', 1, 't', 'T' ].each do |value|
        it "returns true when value is #{value.inspect}" do
          @course.active = value
          @course['active'].should be_true
        end
      end

      [ false, 'false', 'FALSE', '0', 0, 'f', 'F' ].each do |value|
        it "returns false when value is #{value.inspect}" do
          @course.active = value
          @course['active'].should be_false
        end
      end

      [ 'string', 2, 1.0, BigDecimal('1.0'), DateTime.now, Time.now, Date.today, Class, Object.new, ].each do |value|
        it "does not typecast value #{value.inspect}" do
          @course.active = value
          @course['active'].should equal(value)
        end
      end

      it "should respond to requests with ? modifier" do
        @course.active = nil
        @course.active?.should be_false
        @course.active = false
        @course.active?.should be_false
        @course.active = true
        @course.active?.should be_true
      end

      it "should respond to requests with ? modifier on TrueClass" do
        @course.very_active = nil
        @course.very_active?.should be_false
        @course.very_active = false
        @course.very_active?.should be_false
        @course.very_active = true
        @course.very_active?.should be_true
      end
    end

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
    @course.questions = { '0' => {:q => "Test1"}, '1' => {:q => 'Test2'} }
    @course.questions.length.should eql(2)
    @course.questions.last.q.should eql('Test2')
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


  it "should raise an error if attempting to set single value for array type" do
    lambda {
      @course.questions = Question.new(:q => 'test1')
    }.should raise_error
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

describe "Property Class" do

  it "should provide name as string" do
    property = CouchRest::Model::Property.new(:test, String)
    property.name.should eql('test')
    property.to_s.should eql('test')
  end

  it "should provide class from type" do
    property = CouchRest::Model::Property.new(:test, String)
    property.type_class.should eql(String)
  end

  it "should provide base class from type in array" do
    property = CouchRest::Model::Property.new(:test, [String])
    property.type_class.should eql(String)
  end

  it "should raise error if type as string requested" do
    lambda {
      property = CouchRest::Model::Property.new(:test, 'String')
    }.should raise_error
  end

  it "should leave type nil and return class as nil also" do
    property = CouchRest::Model::Property.new(:test, nil)
    property.type.should be_nil
    property.type_class.should be_nil
  end

  it "should convert empty type array to [Object]" do
    property = CouchRest::Model::Property.new(:test, [])
    property.type_class.should eql(Object)
  end

  it "should set init method option or leave as 'new'" do
    # (bad example! Time already typecast)
    property = CouchRest::Model::Property.new(:test, Time)
    property.init_method.should eql('new')
    property = CouchRest::Model::Property.new(:test, Time, :init_method => 'parse')
    property.init_method.should eql('parse')
  end

  ## Property Casting method. More thoroughly tested earlier.

  describe "casting" do
    it "should cast a value" do
      property = CouchRest::Model::Property.new(:test, Date)
      parent = mock("FooObject")
      property.cast(parent, "2010-06-16").should eql(Date.new(2010, 6, 16))
      property.cast_value(parent, "2010-06-16").should eql(Date.new(2010, 6, 16))
    end

    it "should cast an array of values" do
      property = CouchRest::Model::Property.new(:test, [Date])
      parent = mock("FooObject")
      property.cast(parent, ["2010-06-01", "2010-06-02"]).should eql([Date.new(2010, 6, 1), Date.new(2010, 6, 2)])
    end

    it "should set a CastedArray on array of Objects" do
      property = CouchRest::Model::Property.new(:test, [Object])
      parent = mock("FooObject")
      property.cast(parent, ["2010-06-01", "2010-06-02"]).class.should eql(CouchRest::Model::CastedArray)
    end

    it "should not set a CastedArray on array of Strings" do
      property = CouchRest::Model::Property.new(:test, [String])
      parent = mock("FooObject")
      property.cast(parent, ["2010-06-01", "2010-06-02"]).class.should_not eql(CouchRest::Model::CastedArray)
    end

    it "should raise and error if value is array when type is not" do
      property = CouchRest::Model::Property.new(:test, Date)
      parent = mock("FooClass")
      lambda {
        cast = property.cast(parent, [Date.new(2010, 6, 1)])
      }.should raise_error
    end


    it "should set parent as casted_by object in CastedArray" do
      property = CouchRest::Model::Property.new(:test, [Object])
      parent = mock("FooObject")
      property.cast(parent, ["2010-06-01", "2010-06-02"]).casted_by.should eql(parent)
    end

    it "should set casted_by on new value" do
      property = CouchRest::Model::Property.new(:test, CatToy)
      parent = mock("CatObject")
      cast = property.cast(parent, {:name => 'catnip'})
      cast.casted_by.should eql(parent)
    end

  end

end

