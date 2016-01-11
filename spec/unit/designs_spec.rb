require "spec_helper"


describe CouchRest::Model::Designs do

  it "should accessable from model" do
    DesignModel.respond_to?(:design).should be_true
  end

  describe "class methods" do

    describe ".design" do

      before :each do
        @klass = DesignsModel.dup
      end

      describe "without block" do
        it "should create design_doc and all methods" do
          @klass.design
          @klass.should respond_to(:design_doc)
          @klass.should respond_to(:all)
        end

        it "should created named design_doc method and not all" do
          @klass.design :stats
          @klass.should respond_to(:stats_design_doc)
          @klass.should_not respond_to(:all)
        end

        it "should have added itself to a design_blocks array" do
          @klass.design
          blocks = @klass.instance_variable_get(:@_design_blocks)
          blocks.length.should eql(1)
          blocks.first.should eql({:args => [], :block => nil})
        end

        it "should have added itself to a design_blocks array" do
          @klass.design
          blocks = @klass.instance_variable_get(:@_design_blocks)
          blocks.length.should eql(1)
          blocks.first.should eql({:args => [], :block => nil})
        end

        it "should have added itself to a design_blocks array with prefix" do
          @klass.design :stats
          blocks = @klass.instance_variable_get(:@_design_blocks)
          blocks.length.should eql(1)
          blocks.first.should eql({:args => [:stats], :block => nil})
        end
      end

      describe "with block" do
        before :each do
          @block = Proc.new do
            disable_auto_update
          end
          @klass.design &@block
        end

        it "should pass calls to mapper" do
          @klass.design_doc.auto_update.should be_false
        end

        it "should have added itself to a design_blocks array" do
          blocks = @klass.instance_variable_get(:@_design_blocks)
          blocks.length.should eql(1)
          blocks.first.should eql({:args => [], :block => @block})
        end

        it "should handle multiple designs" do
          @block2 = Proc.new do
            view :by_name
          end
          @klass.design :stats, &@block2
          blocks = @klass.instance_variable_get(:@_design_blocks)
          blocks.length.should eql(2)
          blocks.first.should eql({:args => [], :block => @block})
          blocks.last.should eql({:args => [:stats], :block => @block2})
        end
      end

    end

    describe "inheritance" do
      before :each do
        klass = DesignModel.dup
        klass.design do
          view :by_name
        end
        @klass = Class.new(klass)
      end

      it "should add designs to sub module" do
        @klass.should respond_to(:design_doc)
      end

    end

    describe "default_per_page" do
      it "should return 25 default" do
        DesignModel.default_per_page.should eql(25)
      end
    end

    describe ".paginates_per" do
      it "should set the default per page value" do
        DesignModel.paginates_per(21)
        DesignModel.default_per_page.should eql(21)
      end
    end
  end

  describe "Scenario testing" do

    describe "with auto update disabled" do

      before :all do
        reset_test_db!
        @mod = DesignsNoAutoUpdate
      end

      before(:all) do
        id = @mod.to_s
        doc = CouchRest::Document.new("_id" => "_design/#{id}")
        doc["language"] = "javascript"
        doc["views"] = {"all"     => {"map" => "function(doc) { if (doc['type'] == '#{id}') { emit(doc['_id'],1); } }"},
                        "by_title" => {"map" => 
                                  "function(doc) {
                                     if ((doc['type'] == '#{id}') && (doc['title'] != null)) {
                                       emit(doc['title'], 1);
                                     }
                                   }", "reduce" => "function(k,v,r) { return sum(v); }"}}
        DB.save_doc doc
      end

      it "will fail if reduce is not specific in view" do
        @mod.create(:title => 'This is a test')
        lambda { @mod.by_title_fail.first }.should raise_error(CouchRest::NotFound)
      end

      it "will perform view request" do
        @mod.create(:title => 'This is a test')
        @mod.by_title.first.title.should eql("This is a test")
      end

    end

    describe "using views" do

      describe "to find a single item" do
  
        before(:all) do
          reset_test_db!
          %w{aaa bbb ddd eee}.each do |title|
            Course.new(:title => title, :active => (title == 'bbb')).save
          end
        end

        it "should return single matched record with find helper" do
          course = Course.find_by_title('bbb')
          course.should_not be_nil
          course.title.should eql('bbb') # Ensure really is a Course!
        end

        it "should return nil if not found" do
          course = Course.find_by_title('fff')
          course.should be_nil
        end

        it "should peform search on view with two properties" do
          course = Course.find_by_title_and_active(['bbb', true])
          course.should_not be_nil
          course.title.should eql('bbb') # Ensure really is a Course!
        end

        it "should return nil if not found" do
          course = Course.find_by_title_and_active(['bbb', false])
          course.should be_nil
        end

        it "should raise exception if view not present" do
          lambda { Course.find_by_foobar('123') }.should raise_error(NoMethodError)
        end

      end

      describe "a model class with database provided manually" do

        class Unattached < CouchRest::Model::Base
          property :title
          property :questions
          property :professor
          design do
            view :by_title
          end

          # Force the database to always be nil
          def self.database
            nil
          end
        end

        before(:all) do
          reset_test_db!
          @db = DB 
          %w{aaa bbb ddd eee}.each do |title|
            u = Unattached.new(:title => title)
            u.database = @db
            u.save
            @first_id ||= u.id
          end
        end
        it "should barf on all if no database given" do
          expect do 
            Unattached.all.first
          end.to raise_error(CouchRest::Model::DatabaseNotDefined)
        end
        it "should query all" do
          rs = Unattached.all.database(@db).all
          expect(rs.length).to eql(4)
        end
        it "should barf on query if no database given" do
          expect() { Unattached.by_title.all }.to raise_error(CouchRest::Model::DatabaseNotDefined)
        end
        it "should make the design doc upon first query" do
          Unattached.by_title.database(@db)
          doc = Unattached.design_doc
          doc['views']['all']['map'].should include('Unattached')
        end
        it "should merge query params" do
          rs = Unattached.by_title.database(@db).startkey("bbb").endkey("eee")
          rs.length.should == 3
        end
        it "should get from specific database" do
          u = Unattached.get(@first_id, @db)
          u.title.should == "aaa"
        end
        it "should barf on first if no database given" do
          expect{ Unattached.first }.to raise_error(CouchRest::Model::DatabaseNotDefined)
        end
        it "should get first with database set" do
          u = Unattached.all.database(@db).first
          expect(u.title).to match(/\A...\z/)
          expect(u.database).to eql(@db)
        end
        it "should get last" do
          u = Unattached.all.database(@db).last
          u.title.should == "aaa"
        end

      end

      describe "a model with a compound key view" do
        before(:all) do
          reset_test_db!
          written_at = Time.now - 24 * 3600 * 7
          @titles    = ["uniq one", "even more interesting", "less fun", "not junk"]
          @user_ids  = ["quentin", "aaron"]
          @titles.each_with_index do |title,i|
            u = i % 2
            a = Article.new(:title => title, :user_id => @user_ids[u])
            a.date = written_at
            a.save
            written_at += 24 * 3600
          end
        end
        it "should create the design doc" do
          Article.by_user_id_and_date rescue nil
          doc = Article.design_doc
          doc['views']['by_date'].should_not be_nil
        end
        it "should sort correctly" do
          articles = Article.by_user_id_and_date.all
          articles.collect{|a|a['user_id']}.should == ['aaron', 'aaron', 'quentin', 
            'quentin']
          articles[1].title.should == 'not junk'
        end
        it "should be queryable with couchrest options" do
          articles = Article.by_user_id_and_date(:limit => 1, :startkey => 'quentin').all
          articles.length.should == 1
          articles[0].title.should == "even more interesting"
        end
      end


    end

  end

end
