require File.expand_path("../../spec_helper", __FILE__)

require File.join(FIXTURE_PATH, 'more', 'cat')
require File.join(FIXTURE_PATH, 'more', 'article')
require File.join(FIXTURE_PATH, 'more', 'course')
require File.join(FIXTURE_PATH, 'more', 'card')
require File.join(FIXTURE_PATH, 'base')

# TODO Move validations from other specs to here

describe "Validations" do

  describe "Uniqueness" do

    before(:all) do
      @objs = ['title 1', 'title 2', 'title 3'].map{|t| WithUniqueValidation.create(:title => t)}
    end
    
    it "should validate a new unique document" do
      @obj = WithUniqueValidation.create(:title => 'title 4')
      @obj.new?.should_not be_true
      @obj.should be_valid
    end

    it "should not validate a non-unique document" do
      @obj = WithUniqueValidation.create(:title => 'title 1')
      @obj.should_not be_valid
      @obj.errors[:title].should == ["has already been taken"]
    end

    it "should save already created document" do
      @obj = @objs.first
      @obj.save.should_not be_false
      @obj.should be_valid
    end

    it "should allow own view to be specified" do
      # validates_uniqueness_of :code, :view => 'all'
      WithUniqueValidationView.create(:title => 'title 1', :code => '1234')
      @obj = WithUniqueValidationView.new(:title => 'title 5', :code => '1234')
      @obj.should_not be_valid
    end

    it "should raise an error if specified view does not exist" do
      WithUniqueValidationView.validates_uniqueness_of :title, :view => 'fooobar'
      @obj = WithUniqueValidationView.new(:title => 'title 2', :code => '12345')
      lambda {
        @obj.valid?
      }.should raise_error
    end

    context "with a pre-defined view" do
      it "should not try to create new view" do
        @obj = @objs[1]
        @obj.class.should_not_receive('view_by')
        @obj.class.should_receive('has_view?').and_return(true)
        @obj.class.should_receive('view').and_return({'rows' => [ ]})
        @obj.valid?
      end

    end
 
    context "with a proxy parameter" do
      it "should be used" do
        @obj = WithUniqueValidationProxy.new(:title => 'test 6')
        proxy = @obj.should_receive('proxy').and_return(@obj.class)
        @obj.valid?.should be_true
      end

      it "should allow specific view" do
        @obj = WithUniqueValidationProxy.new(:title => 'test 7')
        @obj.class.should_not_receive('view_by')
        proxy = mock('Proxy')
        @obj.should_receive('proxy').and_return(proxy)
        proxy.should_receive('has_view?').and_return(true)
        proxy.should_receive('view').and_return({'rows' => [ ]})
        @obj.valid?
      end

    end

 
  end

end
