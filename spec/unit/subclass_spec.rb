require "spec_helper"

# add a default value
Card.property :bg_color, :default => '#ccc'

class BusinessCard < Card
  property :extension_code
  property :job_title

  validates_presence_of :extension_code
  validates_presence_of :job_title
end

class DesignBusinessCard < BusinessCard
  property :bg_color, :default => '#eee'
end

class OnlineCourse < Course
  property :url
  design do
    view :by_url
  end
end

class Animal < CouchRest::Model::Base
  use_database DB
  property :name
  design do
    view :by_name
  end
end

class Dog < Animal; end

describe "Subclassing a Model" do
  
  before(:each) do
    @card = BusinessCard.new
  end
  
  it "shouldn't messup the parent's properties" do
    expect(Card.properties).not_to eq(BusinessCard.properties)
  end
  
  it "should share the same db default" do
    expect(@card.database.uri).to eq(Card.database.uri)
  end
  
  it "should have kept the validation details" do
    expect(@card).not_to be_valid
  end
  
  it "should have added the new validation details" do
    validated_fields = @card.class.validators.map{|v| v.attributes}.flatten
    expect(validated_fields).to include(:extension_code)
    expect(validated_fields).to include(:job_title)
  end
  
  it "should not add to the parent's validations" do
    validated_fields = Card.validators.map{|v| v.attributes}.flatten
    expect(validated_fields).not_to include(:extension_code)
    expect(validated_fields).not_to include(:job_title) 
  end

  it "should inherit default property values" do
    expect(@card.bg_color).to eq('#ccc')
  end

  it "should be able to overwrite a default property" do
    expect(DesignBusinessCard.new.bg_color).to eq('#eee')
  end

  it "should have a design doc slug based on the subclass name" do
    expect(OnlineCourse.design_doc['_id']).to match(/OnlineCourse$/)
  end

  it "should not add views to the parent's design_doc" do
    expect(Course.design_doc['views'].keys).not_to include('by_url')
  end

  it "should add the parent's views to its design doc" do
    expect(OnlineCourse.design_doc['views'].keys).to include('by_title')
  end

  it "should add the parent's views but alter the model names in map function" do
    expect(OnlineCourse.design_doc['views']['by_title']['map']).to match(/doc\['#{OnlineCourse.model_type_key}'\] == 'OnlineCourse'/)
  end

  it "should have an all view with a guard clause for model == subclass name in the map function" do
    expect(OnlineCourse.design_doc['views']['all']['map']).to match(/if \(doc\['#{OnlineCourse.model_type_key}'\] == 'OnlineCourse'\)/)
  end

end

