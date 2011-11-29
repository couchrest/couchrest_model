require "spec_helper"

describe "Collections" do

  before(:all) do
    reset_test_db!
    titles = ["very uniq one", "really interesting", "some fun",
      "really awesome", "crazy bob", "this rocks", "super rad"]
    titles.each_with_index do |title,i|
      a = Article.new(:title => title, :date => Date.today)
      a.save
    end
    
    titles = ["yesterday very uniq one", "yesterday really interesting", "yesterday some fun",
      "yesterday really awesome", "yesterday crazy bob", "yesterday this rocks"]
    titles.each_with_index do |title,i|
      a = Article.new(:title => title, :date => Date.today - 1)
      a.save
    end
  end 
  it "should return a proxy that looks like an array of 7 Article objects" do
    articles = Article.collection_proxy_for('Article', 'by_date', :descending => true,
      :key => Date.today, :include_docs => true)
    articles.class.should == Array
    articles.size.should == 7
  end
  it "should provide a class method for paginate" do
    articles = Article.paginate(:design_doc => 'Article', :view_name => 'by_date',
      :per_page => 3, :descending => true, :key => Date.today)
    articles.size.should == 3

    articles = Article.paginate(:design_doc => 'Article', :view_name => 'by_date',
      :per_page => 3, :page => 2, :descending => true, :key => Date.today)
    articles.size.should == 3

    articles = Article.paginate(:design_doc => 'Article', :view_name => 'by_date',
      :per_page => 3, :page => 3, :descending => true, :key => Date.today)
    articles.size.should == 1
  end
  it "should provide a class method for paginated_each" do
    options = { :design_doc => 'Article', :view_name => 'by_date',
      :per_page => 3, :page => 1, :descending => true, :key => Date.today }
    Article.paginated_each(options) do |a|
      a.should_not be_nil
    end
  end
  it "should provide a class method to get a collection for a view" do
    articles = Article.find_all_article_details(:key => Date.today)
    articles.class.should == Array
    articles.size.should == 7
  end
  it "should get a subset of articles using paginate" do
    articles = Article.collection_proxy_for('Article', 'by_date', :key => Date.today, :include_docs => true)
    articles.paginate(:page => 1, :per_page => 3).size.should == 3
    articles.paginate(:page => 2, :per_page => 3).size.should == 3
    articles.paginate(:page => 3, :per_page => 3).size.should == 1
  end
  it "should get all articles, a few at a time, using paginated each" do
    articles = Article.collection_proxy_for('Article', 'by_date', :key => Date.today, :include_docs => true)
    articles.paginated_each(:per_page => 3) do |a|
      a.should_not be_nil
    end
  end 

  it "should raise an exception if design_doc is not provided" do
    lambda{Article.collection_proxy_for(nil, 'by_date')}.should raise_error
    lambda{Article.paginate(:view_name => 'by_date')}.should raise_error
  end
  it "should raise an exception if view_name is not provided" do
    lambda{Article.collection_proxy_for('Article', nil)}.should raise_error
    lambda{Article.paginate(:design_doc => 'Article')}.should raise_error
  end
  it "should be able to span multiple keys" do
    articles = Article.collection_proxy_for('Article', 'by_date', :startkey => Date.today - 1, :endkey => Date.today, :include_docs => true)
    articles.paginate(:page => 1, :per_page => 3).size.should == 3
    articles.paginate(:page => 3, :per_page => 3).size.should == 3
    articles.paginate(:page => 5, :per_page => 3).size.should == 1
  end
  it "should pass database parameter to pager" do
    proxy = mock(:proxy)
    proxy.stub!(:paginate)
    ::CouchRest::Model::Collection::CollectionProxy.should_receive(:new).with('database', anything(), anything(), anything(), anything()).and_return(proxy)
    Article.paginate(:design_doc => 'Article', :view_name => 'by_date', :database => 'database')
  end

end
