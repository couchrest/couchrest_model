# encoding: utf-8

require File.expand_path("../../spec_helper", __FILE__)
require File.join(FIXTURE_PATH, 'base')
require File.join(FIXTURE_PATH, 'more', 'article')

describe "Design Documents" do

  describe "CouchRest Extension" do

    it "should have created a checksum method" do
      ::CouchRest::Design.new.should respond_to(:checksum)
    end

    it "should calculate a consistent checksum for model" do
      WithTemplateAndUniqueID.design_doc.checksum.should eql('7786018bacb492e34a38436421a728d0')
    end

    it "should calculate checksum for complex model" do
      Article.design_doc.checksum.should eql('1e6c315853cd5ff10e5c914863aee569')
    end
  end

  describe "basics" do

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
        Article.req_design_doc_refresh
        Article.by_date
        orig = Article.stored_design_doc
        orig['views']['by_date']['map'].should eql(Article.design_doc['views']['by_date']['map'])
      end
      it "should not save design doc if not changed" do
        Article.by_date
        orig = Article.stored_design_doc['_rev']
        Article.req_design_doc_refresh
        Article.by_date
        Article.stored_design_doc['_rev'].should eql(orig)
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
      WithTemplateAndUniqueID.req_design_doc_refresh
      WithTemplateAndUniqueID.refresh_design_doc
      rev = WithTemplateAndUniqueID.design_doc['_rev']
      WithTemplateAndUniqueID.req_design_doc_refresh
      WithTemplateAndUniqueID.refresh_design_doc
      WithTemplateAndUniqueID.design_doc['_rev'].should eql(rev)
    end
  end


end
