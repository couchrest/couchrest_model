require File.expand_path("../../spec_helper", __FILE__)

class UnattachedDoc < CouchRest::Model::Base
  # Note: no use_database here
  property :title
  property :questions
  property :professor
  view_by :title
end


describe "Proxy Class" do

  before(:all) do
    reset_test_db!
    # setup the class default doc to save the design doc
    UnattachedDoc.use_database nil # just to be sure it is really unattached
    @us = UnattachedDoc.on(DB)
    %w{aaa bbb ddd eee}.each do |title|
      u = @us.new(:title => title)
      u.save
      @first_id ||= u.id
    end
  end

  it "should query all" do
    rs = @us.all
    rs.length.should == 4
  end
  it "should count" do
    @us.count.should == 4
  end
  it "should make the design doc upon first query" do
    @us.by_title
    doc = @us.design_doc
    doc['views']['all']['map'].should include('UnattachedDoc')
  end
  it "should merge query params" do
    rs = @us.by_title :startkey=>"bbb", :endkey=>"eee"
    rs.length.should == 3
  end
  it "should query via view" do
    view = @us.view :by_title
    designed = @us.by_title
    view.should == designed
  end
  
  it "should query via first_from_view" do
    UnattachedDoc.should_receive(:first_from_view).with('by_title', 'bbb', {:database => DB})
    @us.first_from_view('by_title', 'bbb')
  end

  it "should query via first_from_view with complex options" do
    UnattachedDoc.should_receive(:first_from_view).with('by_title', {:key => 'bbb', :database => DB})
    @us.first_from_view('by_title', :key => 'bbb')
  end

  it "should query via first_from_view with complex extra options" do
    UnattachedDoc.should_receive(:first_from_view).with('by_title', 'bbb', {:limit => 1, :database => DB})
    @us.first_from_view('by_title', 'bbb', :limit => 1)
  end

  it "should allow dynamic view matching for single elements" do
    @us.should_receive(:first_from_view).with('by_title', 'bbb')
    @us.find_by_title('bbb')
  end

  it "should yield" do
    things = []
    @us.view(:by_title) do |thing|
      things << thing
    end
    things[0]["doc"]["title"].should =='aaa'
  end
  it "should yield with by_key method" do
    things = []
    @us.by_title do |thing|
      things << thing
    end
    things[0]["doc"]["title"].should =='aaa'
  end
  it "should get from specific database" do
    u = @us.get(@first_id)
    u.title.should == "aaa"
  end
  it "should get first" do
    u = @us.first
    u.should == @us.all.first
  end
  
  it "should get last" do
    u = @us.last
    u.should == @us.all.last
  end
  
  it "should set database on first retreived document" do
    u = @us.first
    u.database.should === DB
  end
  it "should set database on all retreived documents" do
    @us.all.each do |u|
      u.database.should === DB
    end
  end
  it "should set database on each retreived document" do
    rs = @us.by_title :startkey=>"bbb", :endkey=>"eee"
    rs.length.should == 3
    rs.each do |u|
      u.database.should === DB
    end
  end
  it "should set database on document retreived by id" do
    u = @us.get(@first_id)
    u.database.should === DB
  end
  it "should not attempt to set database on raw results using :all" do
    @us.all(:raw => true).each do |u|
      u.respond_to?(:database).should be_false
    end
  end
  it "should not attempt to set database on raw results using view" do
    @us.by_title(:raw => true).each do |u|
      u.respond_to?(:database).should be_false
    end
  end
  # Sam Lown 2010-04-07
  # Removed as unclear why this should happen as before my changes 
  # this happend by accident, not explicitly.
  # If requested, this feature should be added as a specific method.
  #
  #it "should clean up design docs left around on specific database" do
  #  @us.by_title
  #  original_id = @us.model_design_doc['_rev']
  #  Unattached.view_by :professor
  #  @us.by_professor
  #  @us.model_design_doc['_rev'].should_not == original_id
  #end
end
