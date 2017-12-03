require "spec_helper"


describe CouchRest::Model::Designs do

  it "should accessable from model" do
    expect(DesignModel.respond_to?(:design)).to be_truthy
  end

  describe "class methods" do

    describe ".design" do

      before :each do
        @klass = DesignsModel.dup
      end

      describe "without block" do
        it "should create design_doc and all methods" do
          @klass.design
          expect(@klass).to respond_to(:design_doc)
          expect(@klass).to respond_to(:all)
        end

        it "should created named design_doc method and not all" do
          @klass.design :stats
          expect(@klass).to respond_to(:stats_design_doc)
          expect(@klass).not_to respond_to(:all)
        end

        it "should have added itself to a design_blocks array" do
          @klass.design
          blocks = @klass.instance_variable_get(:@_design_blocks)
          expect(blocks.length).to eql(1)
          expect(blocks.first).to eql({:args => [], :block => nil})
        end

        it "should have added itself to a design_blocks array" do
          @klass.design
          blocks = @klass.instance_variable_get(:@_design_blocks)
          expect(blocks.length).to eql(1)
          expect(blocks.first).to eql({:args => [], :block => nil})
        end

        it "should have added itself to a design_blocks array with prefix" do
          @klass.design :stats
          blocks = @klass.instance_variable_get(:@_design_blocks)
          expect(blocks.length).to eql(1)
          expect(blocks.first).to eql({:args => [:stats], :block => nil})
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
          expect(@klass.design_doc.auto_update).to be_falsey
        end

        it "should have added itself to a design_blocks array" do
          blocks = @klass.instance_variable_get(:@_design_blocks)
          expect(blocks.length).to eql(1)
          expect(blocks.first).to eql({:args => [], :block => @block})
        end

        it "should handle multiple designs" do
          @block2 = Proc.new do
            view :by_name
          end
          @klass.design :stats, &@block2
          blocks = @klass.instance_variable_get(:@_design_blocks)
          expect(blocks.length).to eql(2)
          expect(blocks.first).to eql({:args => [], :block => @block})
          expect(blocks.last).to eql({:args => [:stats], :block => @block2})
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
        expect(@klass).to respond_to(:design_doc)
      end

    end

    describe "default_per_page" do
      it "should return 25 default" do
        expect(DesignModel.default_per_page).to eql(25)
      end
    end

    describe ".paginates_per" do
      it "should set the default per page value" do
        DesignModel.paginates_per(21)
        expect(DesignModel.default_per_page).to eql(21)
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
        expect { @mod.by_title_fail.first }.to raise_error(CouchRest::NotFound)
      end

      it "will perform view request" do
        @mod.create(:title => 'This is a test')
        expect(@mod.by_title.first.title).to eql("This is a test")
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
          expect(course).not_to be_nil
          expect(course.title).to eql('bbb') # Ensure really is a Course!
        end

        it "should return nil if not found" do
          course = Course.find_by_title('fff')
          expect(course).to be_nil
        end

        it "should peform search on view with two properties" do
          course = Course.find_by_title_and_active(['bbb', true])
          expect(course).not_to be_nil
          expect(course.title).to eql('bbb') # Ensure really is a Course!
        end

        it "should return nil if not found" do
          course = Course.find_by_title_and_active(['bbb', false])
          expect(course).to be_nil
        end

        it "should raise exception if view not present" do
          expect { Course.find_by_foobar('123') }.to raise_error(NoMethodError)
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
          expect(doc['views']['by_date']).not_to be_nil
        end
        it "should sort correctly" do
          articles = Article.by_user_id_and_date.all
          expect(articles.collect{|a|a['user_id']}).to eq(['aaron', 'aaron', 'quentin', 
            'quentin'])
          expect(articles[1].title).to eq('not junk')
        end
        it "should be queryable with couchrest options" do
          articles = Article.by_user_id_and_date(:limit => 1, :startkey => 'quentin').all
          expect(articles.length).to eq(1)
          expect(articles[0].title).to eq("even more interesting")
        end
      end


    end

  end

end
