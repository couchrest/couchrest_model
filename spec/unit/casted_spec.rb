require "spec_helper"

class Driver < CouchRest::Model::Base
  use_database DB
  # You have to add a casted_by accessor if you want to reach a casted extended doc parent
  attr_accessor :casted_by
  
  property :name
end

class Car < CouchRest::Model::Base
  use_database DB
  
  property :name
  property :driver, Driver
end

describe "casting an extended document" do
  
  before(:each) do
    @driver = Driver.new(:name => 'Matt')
    @car    = Car.new(:name => 'Renault 306', :driver => @driver)
  end

  it "should retain all properties of the casted attribute" do
    expect(@car.driver).to eq(@driver)
  end
  
  it "should let the casted document know who casted it" do
    expect(@car.driver.casted_by).to eq(@car)
  end
end

describe "assigning a value to casted attribute after initializing an object" do

  before(:each) do
    @car    = Car.new(:name => 'Renault 306')
    @driver = Driver.new(:name => 'Matt')
  end
  
  it "should not create an empty casted object" do
    expect(@car.driver).to be_nil
  end
  
  it "should let you assign the value" do
    @car.driver = @driver
    expect(@car.driver.name).to eq('Matt')
  end
  
  it "should cast attribute" do
    @car.driver = JSON.parse(@driver.to_json)
    expect(@car.driver).to be_instance_of(Driver)
  end

end

describe "casting a model from parsed JSON" do

  before(:each) do
    @driver = Driver.new(:name => 'Matt')
    @car    = Car.new(:name => 'Renault 306', :driver => @driver)
    @new_car = Car.new(JSON.parse(@car.to_json))
  end

  it "should cast casted attribute" do
    expect(@new_car.driver).to be_instance_of(Driver)
  end
  
  it "should retain all properties of the casted attribute" do
    expect(@new_car.driver).to eq(@driver)
  end
end
