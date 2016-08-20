require "spec_helper"

describe CouchRest::Model::Validations do

  describe "Uniqueness" do

    context "basic" do
      before(:all) do
        @objs = ['title 1', 'title 2', 'title 3'].map{|t| WithUniqueValidation.create(:title => t)}
      end

      it "should create a new view if none defined before performing" do
        expect(WithUniqueValidation.design_doc.has_view?(:by_title)).to be_truthy
      end

      it "should validate a new unique document" do
        @obj = WithUniqueValidation.create(:title => 'title 4')
        expect(@obj.new?).not_to be_truthy
        expect(@obj).to be_valid
      end

      it "should not validate a non-unique document" do
        @obj = WithUniqueValidation.create(:title => 'title 1')
        expect(@obj).not_to be_valid
        expect(@obj.errors[:title]).to eq(["has already been taken"])
      end

      it "should save already created document" do
        @obj = @objs.first
        expect(@obj.save).not_to be_falsey
        expect(@obj).to be_valid
      end


      it "should allow own view to be specified" do
        # validates_uniqueness_of :code, :view => 'all'
        WithUniqueValidationView.create(:title => 'title 1', :code => '1234')
        @obj = WithUniqueValidationView.new(:title => 'title 5', :code => '1234')
        expect(@obj).not_to be_valid
      end

      it "should raise an error if specified view does not exist" do
        WithUniqueValidationView.validates_uniqueness_of :title, :view => 'fooobar'
        @obj = WithUniqueValidationView.new(:title => 'title 2', :code => '12345')
        expect {
          @obj.valid?
        }.to raise_error(/WithUniqueValidationView.fooobar does not exist for validation/)
      end

      it "should not try to create a defined view" do
        WithUniqueValidationView.validates_uniqueness_of :title, :view => 'fooobar'
        expect(WithUniqueValidationView.design_doc.has_view?('fooobar')).to be_falsey
        expect(WithUniqueValidationView.design_doc.has_view?('by_title')).to be_falsey
      end


      it "should not try to create new view when already defined" do
        @obj = @objs[1]
        expect(@obj.class.design_doc).not_to receive('create_view')
        @obj.valid?
      end
    end

    context "with a proxy parameter" do

      it "should create a new view despite proxy" do
        expect(WithUniqueValidationProxy.design_doc.has_view?(:by_title)).to be_truthy
      end

      it "should be used" do
        @obj = WithUniqueValidationProxy.new(:title => 'test 6')
        proxy = expect(@obj).to receive('proxy').and_return(@obj.class)
        expect(@obj.valid?).to be_truthy
      end

      it "should allow specific view" do
        @obj = WithUniqueValidationProxy.new(:title => 'test 7')
        expect(@obj.class).not_to receive('by_title')
        view = double('View')
        allow(view).to receive(:rows).and_return([])
        proxy = double('Proxy')
        expect(proxy).to receive('by_title').and_return(view)
        expect(proxy).to receive('respond_to?').with('by_title').and_return(true)
        expect(@obj).to receive('proxy').and_return(proxy)
        @obj.valid?
      end
    end

    context "when proxied" do
      it "should lookup the model_proxy" do
        view = double('View')
        allow(view).to receive(:rows).and_return([])
        mp = double(:ModelProxy)
        expect(mp).to receive(:by_title).and_return(view)
        @obj = WithUniqueValidation.new(:title => 'test 8')
        allow(@obj).to receive(:model_proxy).twice.and_return(mp)
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
        expect(@obj).to be_valid
      end

      it "should validate unique document outside of scope" do
        @obj = WithScopedUniqueValidation.create(:title => 'title 1', :parent_id => 2)
        expect(@obj).to be_valid
      end

      it "should validate non-unique document" do
        @obj = WithScopedUniqueValidation.create(:title => 'title 1', :parent_id => 1)
        expect(@obj).not_to be_valid
        expect(@obj.errors[:title]).to eq(["has already been taken"])
      end

      it "should validate unique document will nil scope" do
        @obj = WithScopedUniqueValidation.create(:title => 'title 4', :parent_id => nil)
        expect(@obj).to be_valid
      end

      it "should validate non-unique document with nil scope" do
        @obj = WithScopedUniqueValidation.create(:title => 'title 1', :parent_id => nil)
        expect(@obj).not_to be_valid
        expect(@obj.errors[:title]).to eq(["has already been taken"])
      end

    end

  end

end
