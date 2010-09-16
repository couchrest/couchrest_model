require File.expand_path("../../spec_helper", __FILE__)

class DirtyModel < CouchRest::Model::Base
  use_database TEST_SERVER.default_database
  property :name
  property :color
  validates_presence_of :name
end

describe 'Dirty Tracking', '#changed?' do
  before(:each) do
    @dm = DirtyModel.new
    @dm.name = 'will'
  end

  it 'brand new models should not be changed by default' do
    DirtyModel.new.should_not be_changed
  end

  it 'save should reset changed?' do
    @dm.should be_changed
    @dm.save
    @dm.should_not be_changed
  end

  it 'save! should reset changed?' do
    @dm.should be_changed
    @dm.save!
    @dm.should_not be_changed
  end

  it 'a failed save should preserve changed?' do
    @dm.name = ''
    @dm.should be_changed
    @dm.save.should be_false
    @dm.should be_changed
  end

  it 'should be true if there have been changes' do
    @dm.name = 'not will'
    @dm.should be_changed
  end
end

describe 'Dirty Tracking', '#changed' do
  it 'should be an array of the changed attributes' do
    dm = DirtyModel.new
    dm.changed.should == []
    dm.name = 'will'
    dm.changed.should == ['name']
    dm.color = 'red'
    dm.changed.should =~ ['name', 'color']
  end
end

describe 'Dirty Tracking', '#changes' do
  it 'should be a Map of changed attrs => [original value, new value]' do
    dm = DirtyModel.new(:name => 'will', :color => 'red')
    dm.save!
    dm.should_not be_changed

    dm.name = 'william'
    dm.color = 'blue'

    dm.changes.should == { 'name' => ['will', 'william'], 'color' => ['red', 'blue'] }
  end
end

describe 'Dirty Tracking', '#previous_changes' do
  it 'should store the previous changes after a save' do
    dm = DirtyModel.new(:name => 'will', :color => 'red')
    dm.save!
    dm.should_not be_changed

    dm.name = 'william'
    dm.save!

    dm.previous_changes.should == { 'name' => ['will', 'william'] }
  end
end

describe 'Dirty Tracking', 'attribute methods' do
  before(:each) do
     @dm = DirtyModel.new(:name => 'will', :color => 'red')
     @dm.save!
  end

  describe '#<attr>_changed?' do
    it 'it should know if a specific property was changed' do
      @dm.name = 'william'
      @dm.should     be_name_changed
      @dm.should_not be_color_changed
    end
  end

  describe 'Dirty Tracking', '#<attr>_change' do
    it 'should be an array of [original value, current value]' do
      @dm.name = 'william'
      @dm.name_change.should == ['will', 'william']
    end
  end

  describe 'Dirty Tracking', '#<attr>_was' do
    it 'should return what the attribute was' do
      @dm.name = 'william'
      @dm.name_was.should == 'will'
    end
  end

  describe 'Dirty Tracking', '#reset_<attr>!' do
    it 'should reset the attribute to what it was' do
      @dm.name = 'william'

      @dm.reset_name!
      @dm.name.should == 'will'
    end
  end

  describe 'Dirty Tracking', '#<attr>_will_change!' do
    it 'should manually mark the attribute as changed' do
      @dm.should_not be_name_changed
      @dm.name_will_change!
      @dm.should be_name_changed
    end
  end
end
