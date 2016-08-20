require 'spec_helper'

describe "Model attachments" do
  
  describe "#has_attachment?" do
    before(:each) do
      reset_test_db!
      @obj = Basic.new
      expect(@obj.save).to be_truthy
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
    end
  
    it 'should return false if there is no attachment' do
      expect(@obj.has_attachment?('bogus')).to be_falsey
    end
  
    it 'should return true if there is an attachment' do
      expect(@obj.has_attachment?(@attachment_name)).to be_truthy
    end
  
    it 'should return true if an object with an attachment is reloaded' do
      expect(@obj.save).to be_truthy
      reloaded_obj = Basic.get(@obj.id)
      expect(reloaded_obj.has_attachment?(@attachment_name)).to be_truthy
    end
  
    it 'should return false if an attachment has been removed' do
      @obj.delete_attachment(@attachment_name)
      expect(@obj.has_attachment?(@attachment_name)).to be_falsey
    end
    
    it 'should return false if an attachment has been removed and reloaded' do
      @obj.delete_attachment(@attachment_name)
      reloaded_obj = Basic.get(@obj.id)
      expect(reloaded_obj.has_attachment?(@attachment_name)).to be_falsey
    end
    
  end

  describe "creating an attachment" do
    before(:each) do
      @obj = Basic.new
      expect(@obj.save).to be_truthy
      @file_ext = File.open(FIXTURE_PATH + '/attachments/test.html')
      @file_no_ext = File.open(FIXTURE_PATH + '/attachments/README')
      @attachment_name = 'my_attachment'
      @content_type = 'media/mp3'
    end
  
    it "should create an attachment from file with an extension" do
      @obj.create_attachment(:file => @file_ext, :name => @attachment_name)
      expect(@obj.save).to be_truthy
      reloaded_obj = Basic.get(@obj.id)
      expect(reloaded_obj.attachments[@attachment_name]).not_to be_nil
    end
  
    it "should create an attachment from file without an extension" do
      @obj.create_attachment(:file => @file_no_ext, :name => @attachment_name)
      expect(@obj.save).to be_truthy
      reloaded_obj = Basic.get(@obj.id)
      expect(reloaded_obj.attachments[@attachment_name]).not_to be_nil
    end
  
    it 'should raise ArgumentError if :file is missing' do
      expect{ @obj.create_attachment(:name => @attachment_name) }.to raise_error(ArgumentError, /:file/)
    end
  
    it 'should raise ArgumentError if :name is missing' do
      expect{ @obj.create_attachment(:file => @file_ext) }.to raise_error(ArgumentError, /:name/)
    end
  
    it 'should set the content-type if passed' do
      @obj.create_attachment(:file => @file_ext, :name => @attachment_name, :content_type => @content_type)
      expect(@obj.attachments[@attachment_name]['content_type']).to eq(@content_type)
    end

    it "should detect the content-type automatically" do
      @obj.create_attachment(:file => File.open(FIXTURE_PATH + '/attachments/couchdb.png'), :name => "couchdb.png")
      expect(@obj.attachments['couchdb.png']['content_type']).to eq("image/png") 
    end

    it "should use name to detect the content-type automatically if no file" do
      file = File.open(FIXTURE_PATH + '/attachments/couchdb.png')
      allow(file).to receive(:path).and_return("badfilname")
      @obj.create_attachment(:file => File.open(FIXTURE_PATH + '/attachments/couchdb.png'), :name => "couchdb.png")
      expect(@obj.attachments['couchdb.png']['content_type']).to eq("image/png") 
    end

  end

  describe 'reading, updating, and deleting an attachment' do
    before(:each) do
      @obj = Basic.new
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
      expect(@obj.save).to be_truthy
      @file.rewind
      @content_type = 'media/mp3'
    end
  
    it 'should read an attachment that exists' do
      expect(@obj.read_attachment(@attachment_name)).to eq(@file.read)
    end
  
    it 'should update an attachment that exists' do
      file = File.open(FIXTURE_PATH + '/attachments/README')
      expect(@file).not_to eq(file)
      @obj.update_attachment(:file => file, :name => @attachment_name)
      @obj.save
      reloaded_obj = Basic.get(@obj.id)
      file.rewind
      expect(reloaded_obj.read_attachment(@attachment_name)).not_to eq(@file.read)
      expect(reloaded_obj.read_attachment(@attachment_name)).to eq(file.read)
    end
  
    it 'should set the content-type if passed' do
      file = File.open(FIXTURE_PATH + '/attachments/README')
      expect(@file).not_to eq(file)
      @obj.update_attachment(:file => file, :name => @attachment_name, :content_type => @content_type)
      expect(@obj.attachments[@attachment_name]['content_type']).to eq(@content_type)
    end
  
    it 'should delete an attachment that exists' do
      @obj.delete_attachment(@attachment_name)
      @obj.save
      expect{Basic.get(@obj.id).read_attachment(@attachment_name)}.to raise_error(/404 Not Found/)
    end
  end

  describe "#attachment_url" do
    before(:each) do
      @obj = Basic.new
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
      expect(@obj.save).to be_truthy
    end
  
    it 'should return nil if attachment does not exist' do
      expect(@obj.attachment_url('bogus')).to be_nil
    end
  
    it 'should return the attachment URL as specified by CouchDB HttpDocumentApi' do
      expect(@obj.attachment_url(@attachment_name)).to eq("#{Basic.database}/#{@obj.id}/#{@attachment_name}")
    end
    
    it 'should return the attachment URI' do
      expect(@obj.attachment_uri(@attachment_name)).to eq("#{Basic.database.uri}/#{@obj.id}/#{@attachment_name}")
    end
  end

  describe "#attachments" do
    before(:each) do
      @obj = Basic.new
      @file = File.open(FIXTURE_PATH + '/attachments/test.html')
      @attachment_name = 'my_attachment'
      @obj.create_attachment(:file => @file, :name => @attachment_name)
      expect(@obj.save).to be_truthy
    end
  
    it 'should return an empty Hash when document does not have any attachment' do
      new_obj = Basic.new
      expect(new_obj.save).to be_truthy
      expect(new_obj.attachments).to eq({})
    end
  
    it 'should return a Hash with all attachments' do
      @file.rewind
      expect(@obj.attachments).to eq({ @attachment_name =>{ "data" => "PCFET0NUWVBFIGh0bWw+CjxodG1sPgogIDxoZWFkPgogICAgPHRpdGxlPlRlc3Q8L3RpdGxlPgogIDwvaGVhZD4KICA8Ym9keT4KICAgIDxwPgogICAgICBUZXN0CiAgICA8L3A+CiAgPC9ib2R5Pgo8L2h0bWw+Cg==", "content_type" => "text/html"}})
    end
  
  end
end
