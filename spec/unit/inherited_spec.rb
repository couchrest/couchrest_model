require 'spec_helper'

class PlainParent
  class_attribute :foo
  self.foo = :bar
end

class PlainChild < PlainParent
end

class ExtendedParent < CouchRest::Model::Base
  class_attribute :foo
  self.foo = :bar
end

class ExtendedChild < ExtendedParent
end

describe "Using chained inheritance without CouchRest::Model::Base" do
  it "should preserve inheritable attributes" do
    expect(PlainParent.foo).to eq(:bar)
    expect(PlainChild.foo).to eq(:bar)
  end
end

describe "Using chained inheritance with CouchRest::Model::Base" do
  it "should preserve inheritable attributes" do
    expect(ExtendedParent.foo).to eq(:bar)
    expect(ExtendedChild.foo).to eq(:bar)
  end
end


