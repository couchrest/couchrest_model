require 'question'
require 'person'

class Course < CouchRest::Model::Base
  use_database TEST_SERVER.default_database
  
  property :title, String
  property :questions, [Question]
  property :professor, Person
  property :participants, [Object]
  property :ends_at, Time
  property :estimate, Float
  property :hours, Integer
  property :profit, BigDecimal
  property :started_on, :type => Date
  property :updated_at, DateTime
  property :active, :type => TrueClass
  property :very_active, :type => TrueClass
  property :klass, :type => Class

  design do
    view :by_title
    view :by_title_and_active

    view :by_dept, :ducktype => true

    view :by_active, :map => "function(d) { if (d['#{model_type_key}'] == 'Course' && d['active']) { emit(d['updated_at'], 1); }}", :reduce => "function(k,v,r) { return sum(v); }"
  end

end
