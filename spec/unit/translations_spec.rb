# encoding: utf-8
require "spec_helper"

describe "ActiveModel Translations" do

  describe ".human_attribute_name" do
    it "should provide translation" do
      expect(Card.human_attribute_name(:first_name)).to eql("First name")
    end
  end

  describe ".i18n_scope" do
    it "should provide activemodel default" do
      expect(Card.i18n_scope).to eql(:couchrest)
    end
  end

  describe ".lookup_ancestors" do
    it "should provide basic lookup" do
      expect(Cat.lookup_ancestors).to eql([Cat])
    end

    it "should provide lookup with ancestors" do
      expect(ChildCat.lookup_ancestors).to eql([ChildCat, Cat])
    end

    it "should provide Base if request directly" do
      expect(CouchRest::Model::Base.lookup_ancestors).to eql([CouchRest::Model::Base])
    end
  end
end
