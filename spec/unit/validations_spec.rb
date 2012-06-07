require "spec_helper"

describe CouchRest::Model::Validations do

  describe "Uniqueness" do

    context "basic" do
      before(:all) do
        @objs = ['title 1', 'title 2', 'title 3'].map{|t| WithUniqueValidation.create(:title => t)}
      end

      it "should create a new view if none defined before performing" do
        WithUniqueValidation.design_doc.has_view?(:by_title).should be_true
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

      it "should not try to create a defined view" do
        WithUniqueValidationView.validates_uniqueness_of :title, :view => 'fooobar'
        WithUniqueValidationView.design_doc.has_view?('fooobar').should be_false
        WithUniqueValidationView.design_doc.has_view?('by_title').should be_false
      end


      it "should not try to create new view when already defined" do
        @obj = @objs[1]
        @obj.class.design_doc.should_not_receive('create_view')
        @obj.valid?
      end
    end

    context "with a proxy parameter" do

      it "should create a new view despite proxy" do
        WithUniqueValidationProxy.design_doc.has_view?(:by_title).should be_true
      end

      it "should be used" do
        @obj = WithUniqueValidationProxy.new(:title => 'test 6')
        proxy = @obj.should_receive('proxy').and_return(@obj.class)
        @obj.valid?.should be_true
      end

      it "should allow specific view" do
        @obj = WithUniqueValidationProxy.new(:title => 'test 7')
        @obj.class.should_not_receive('by_title')
        view = mock('View')
        view.stub!(:rows).and_return([])
        proxy = mock('Proxy')
        proxy.should_receive('by_title').and_return(view)
        proxy.should_receive('respond_to?').with('by_title').and_return(true)
        @obj.should_receive('proxy').and_return(proxy)
        @obj.valid?
      end
    end

    context "when proxied" do
      it "should lookup the model_proxy" do
        view = mock('View')
        view.stub!(:rows).and_return([])
        mp = mock(:ModelProxy)
        mp.should_receive(:by_title).and_return(view)
        @obj = WithUniqueValidation.new(:title => 'test 8')
        @obj.stub!(:model_proxy).twice.and_return(mp)
        @obj.valid?
      end
    end

    context "with a scope" do
      before(:all) do
        @objs = [['title 1', 1], ['title 2', 1], ['title 3', 1]].map{|t| WithScopedUniqueValidation.create(:title => t[0], :parent_id => t[1])}
        @objs_nil = [['title 1', nil], ['title 2', nil], ['title 3', nil]].map{|t| WithScopedUniqueValidation.create(:title => t[0], :parent_id => t[1])}
      end

      it "should create the view" do
        @objs.first.class.design_doc.has_view?('by_parent_id_and_title')
      end

      it "should validate unique document" do
        @obj = WithScopedUniqueValidation.create(:title => 'title 4', :parent_id => 1)
        @obj.should be_valid
      end

      it "should validate unique document outside of scope" do
        @obj = WithScopedUniqueValidation.create(:title => 'title 1', :parent_id => 2)
        @obj.should be_valid
      end

      it "should validate non-unique document" do
        @obj = WithScopedUniqueValidation.create(:title => 'title 1', :parent_id => 1)
        @obj.should_not be_valid
        @obj.errors[:title].should == ["has already been taken"]
      end

      it "should validate unique document will nil scope" do
        @obj = WithScopedUniqueValidation.create(:title => 'title 4', :parent_id => nil)
        @obj.should be_valid
      end

      it "should validate non-unique document with nil scope" do
        @obj = WithScopedUniqueValidation.create(:title => 'title 1', :parent_id => nil)
        @obj.should_not be_valid
        @obj.errors[:title].should == ["has already been taken"]
      end

    end

  end

end
