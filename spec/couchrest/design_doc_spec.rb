# encoding: utf-8

require File.expand_path("../../spec_helper", __FILE__)
require File.join(FIXTURE_PATH, 'base')
require File.join(FIXTURE_PATH, 'more', 'article')

describe "Design Documents" do

  before :all do
    reset_test_db!
  end

  describe "CouchRest Extension" do

    it "should have created a checksum! method" do
      ::CouchRest::Design.new.should respond_to(:checksum!)
    end

    it "should calculate a consistent checksum for model" do
      WithTemplateAndUniqueID.design_doc.checksum!.should eql('7786018bacb492e34a38436421a728d0')
    end

    it "should calculate checksum for complex model" do
      Article.design_doc.checksum!.should eql('1e6c315853cd5ff10e5c914863aee569')
    end

    it "should cache the generated checksum value" do
      Article.design_doc.checksum!
      Article.design_doc['couchrest-hash'].should_not be_blank
    end
  end

  describe "class methods" do

    describe ".design_doc" do
      it "should provide Design document" do
        Article.design_doc.should be_a(::CouchRest::Design)
      end
    end

    describe ".design_doc_id" do
      it "should provide a reasonable id" do
        Article.design_doc_id.should eql("_design/Article")
      end
    end

    describe ".design_doc_slug" do
      it "should provide slug part of design doc" do
        Article.design_doc_slug.should eql('Article')
      end
    end

    describe ".design_doc_full_url" do
      it "should provide complete url" do
        Article.design_doc_full_url.should eql("#{DB.uri}/_design/Article")
      end
      it "should provide complete url for new DB" do
        db = mock("Database")
        db.should_receive(:uri).and_return('db')
        Article.design_doc_full_url(db).should eql("db/_design/Article")
      end
    end

    describe ".stored_design_doc" do
      it "should load a stored design from the database" do
        Article.by_date
        Article.stored_design_doc['_rev'].should_not be_blank
      end
      it "should return nil if not already stored" do
        WithDefaultValues.stored_design_doc.should be_nil
      end
    end

    describe ".save_design_doc" do
      it "should call up the design updater" do
        Article.should_receive(:update_design_doc).with('db', false)
        Article.save_design_doc('db')
      end
    end

    describe ".save_design_doc!" do
      it "should call save_design_doc with force" do
        Article.should_receive(:save_design_doc).with('db', true)
        Article.save_design_doc!('db')
      end
    end

  end

  describe "basics" do

    before :all do
      reset_test_db!
    end

    it "should have been instantiated with views" do
      d = Article.design_doc
      d['views']['all']['map'].should include('Article')
    end

    it "should not have been saved yet" do
      lambda { Article.database.get(Article.design_doc.id) }.should raise_error(RestClient::ResourceNotFound)
    end

    describe "after requesting a view" do
      before :each do
        Article.all
      end
      it "should have saved the design doc after view request" do
        Article.database.get(Article.design_doc.id).should_not be_nil
      end
    end

    describe "model with simple views" do
      before(:all) do
        Article.all.map{|a| a.destroy(true)}
        Article.database.bulk_delete
        written_at = Time.now - 24 * 3600 * 7
        @titles = ["this and that", "also interesting", "more fun", "some junk"]
        @titles.each do |title|
          a = Article.new(:title => title)
          a.date = written_at
          a.save
          written_at += 24 * 3600
        end
      end

      it "will send request for the saved design doc on view request" do
        reset_test_db!
        Article.should_receive(:stored_design_doc).and_return(nil)
        Article.by_date
      end

      it "should have generated a design doc" do
        Article.design_doc["views"]["by_date"].should_not be_nil
      end
      it "should save the design doc when view requested" do
        Article.by_date
        doc = Article.database.get Article.design_doc.id
        doc['views']['by_date'].should_not be_nil
      end
      it "should save design doc if a view changed" do
        Article.by_date
        orig = Article.stored_design_doc
        design = Article.design_doc
        view = design['views']['by_date']['map']
        design['views']['by_date']['map'] = view + '  ' # little bit of white space
        Article.by_date
        Article.stored_design_doc['_rev'].should_not eql(orig['_rev'])
        orig['views']['by_date']['map'].should_not eql(Article.design_doc['views']['by_date']['map'])
      end
      it "should not save design doc if not changed" do
        Article.by_date
        orig = Article.stored_design_doc['_rev']
        Article.by_date
        Article.stored_design_doc['_rev'].should eql(orig)
      end
    end

    describe "when auto_update_design_doc false" do
  
      before :all do
        Article.auto_update_design_doc = false
        Article.save_design_doc!
      end

      after :all do
        Article.auto_update_design_doc = true
      end

      it "will not send a request for the saved design doc" do
        Article.should_not_receive(:stored_design_doc)
        Article.by_date
      end

      it "will not update stored design doc if view changed" do
        Article.by_date
        orig = Article.stored_design_doc
        design = Article.design_doc
        view = design['views']['by_date']['map']
        design['views']['by_date']['map'] = view + '  '
        Article.by_date
        Article.stored_design_doc['_rev'].should eql(orig['_rev'])
      end

      it "will update stored design if forced" do
        Article.by_date
        orig = Article.stored_design_doc
        design = Article.design_doc
        view = design['views']['by_date']['map']
        design['views']['by_date']['map'] = view + '  '
        Article.save_design_doc!
        Article.stored_design_doc['_rev'].should_not eql(orig['_rev'])
      end
    end
  end

  describe "lazily refreshing the design document" do
    before(:all) do
      @db = reset_test_db!
      WithTemplateAndUniqueID.new('important-field' => '1').save
    end
    it "should not save the design doc twice" do
      WithTemplateAndUniqueID.all
      rev = WithTemplateAndUniqueID.design_doc['_rev']
      WithTemplateAndUniqueID.design_doc['_rev'].should eql(rev)
    end
  end


end
