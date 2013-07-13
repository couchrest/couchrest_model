# encoding: utf-8
require "spec_helper"

describe "ActiveModel Translations" do

  describe ".human_attribute_name" do
    it "should provide translation" do
      Card.human_attribute_name(:first_name).should eql("First name")
    end
  end

  describe ".i18n_scope" do
    it "should provide activemodel default" do
      Card.i18n_scope.should eql(:couchrest)
    end
  end

  describe ".lookup_ancestors" do
    it "should provide basic lookup" do
      Cat.lookup_ancestors.should eql([Cat])
    end

    it "should provide lookup with ancestors" do
      ChildCat.lookup_ancestors.should eql([ChildCat, Cat])
    end

    it "should provide Base if request directly" do
      CouchRest::Model::Base.lookup_ancestors.should eql([CouchRest::Model::Base])
    end
  end
end
