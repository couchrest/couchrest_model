# encoding: utf-8

require 'spec_helper'

describe CouchRest::Model::Designs::DesignDoc do

  before :all do
    reset_test_db!
  end






  describe "Checksum calculations" do

    it "should calculate a consistent checksum for model" do
      WithTemplateAndUniqueID.design_doc.checksum!.should eql('caa2b4c27abb82b4e37421de76d96ffc')
    end

    it "should calculate checksum for complex model" do
      Article.design_doc.checksum!.should eql('70dff8caea143bf40fad09adf0701104')
    end

    it "should cache the generated checksum value" do
      Article.design_doc.checksum!
      Article.design_doc['couchrest-hash'].should_not be_blank
    end

  end


end
