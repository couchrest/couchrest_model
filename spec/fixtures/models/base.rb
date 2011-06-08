class WithDefaultValues < CouchRest::Model::Base
  use_database TEST_SERVER.default_database
  property :preset, Object, :default => {:right => 10, :top_align => false}
  property :set_by_proc, Time, :default => Proc.new{Time.now}
  property :tags, [String], :default => []
  property :read_only_with_default, :default => 'generic', :read_only => true
  property :default_false, TrueClass, :default => false
  property :name
  timestamps!
end

class WithSimplePropertyType < CouchRest::Model::Base
  use_database TEST_SERVER.default_database
  property :name, String
  property :preset, String, :default => 'none'
  property :tags, [String]
  timestamps!
end

class WithCallBacks < CouchRest::Model::Base
  use_database TEST_SERVER.default_database
  property :name
  property :run_before_validation
  property :run_after_validation
  property :run_before_save
  property :run_after_save
  property :run_before_create
  property :run_after_create
  property :run_before_update
  property :run_after_update

  validates_presence_of :run_before_validation
  
  before_validation do |object|
    object.run_before_validation = true
  end
  after_validation do |object| 
    object.run_after_validation = true
  end
  before_save do |object| 
    object.run_before_save = true
  end
  after_save do |object| 
    object.run_after_save = true
  end
  before_create do |object| 
    object.run_before_create = true
  end
  after_create do |object| 
    object.run_after_create = true
  end
  before_update do |object| 
    object.run_before_update = true
  end
  after_update do |object| 
    object.run_after_update = true
  end
  
  property :run_one
  property :run_two
  property :run_three
  
  before_save :run_one_method, :run_two_method do |object| 
    object.run_three = true
  end
  def run_one_method
    self.run_one = true
  end
  def run_two_method
    self.run_two = true
  end
  
  attr_accessor :run_it
  property :conditional_one
  property :conditional_two
  
  before_save :conditional_one_method, :conditional_two_method, :if => proc { self.run_it }
  def conditional_one_method
    self.conditional_one = true
  end
  def conditional_two_method
    self.conditional_two = true
  end
end

# Following two fixture classes have __intentionally__ diffent syntax for setting the validation context
class WithContextualValidationOnCreate < CouchRest::Model::Base
  property(:name, String)
  validates(:name, :presence => {:on => :create})
end

class WithContextualValidationOnUpdate < CouchRest::Model::Base
  property(:name, String)
  validates(:name, :presence => true, :on => :update)
end

class WithTemplateAndUniqueID < CouchRest::Model::Base
  use_database TEST_SERVER.default_database
  unique_id do |model|
    model.slug
  end
  property :slug
  property :preset, :default => 'value'
  property :has_no_default
end

class WithGetterAndSetterMethods < CouchRest::Model::Base
  use_database TEST_SERVER.default_database

  property :other_arg
  def arg
    other_arg
  end

  def arg=(value)
    self.other_arg = "foo-#{value}"
  end
end

class WithAfterInitializeMethod < CouchRest::Model::Base
  use_database TEST_SERVER.default_database

  property :some_value

  def after_initialize
    self.some_value ||= "value"
  end

end

class WithUniqueValidation < CouchRest::Model::Base
  use_database DB
  property :title
  validates_uniqueness_of :title
end
class WithUniqueValidationProxy < CouchRest::Model::Base
  use_database DB
  property :title
  validates_uniqueness_of :title, :proxy => 'proxy'
end
class WithUniqueValidationView < CouchRest::Model::Base
  use_database DB
  attr_accessor :code
  unique_id :code
  def code
    @code
  end
  property :title

  validates_uniqueness_of :code, :view => 'all'
end

class WithScopedUniqueValidation < CouchRest::Model::Base
  use_database DB

  property :parent_id
  property :title

  validates_uniqueness_of :title, :scope => :parent_id
end


