require File.join(FIXTURE_PATH, 'more', 'question')
require File.join(FIXTURE_PATH, 'more', 'person')

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
  property :updated_at, :type => DateTime
  property :active, :type => TrueClass
  property :very_active, :type => TrueClass
  property :klass, :type => Class
  
  view_by :title
  view_by :title, :active
  view_by :dept, :ducktype => true

end
