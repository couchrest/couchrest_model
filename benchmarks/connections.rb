#
# Simple Benchmarking Script.
#
# Meant to test performance for different types on connections under a typical
# scenario of requesting multiple objects from the database in series.
#
# To run, use `bundle install` then:
#
#   bundle exec ruby connections.rb
#

require 'rubygems'
require 'bundler/setup'

require 'benchmark'
require 'couchrest_model'
require 'faker'

class SampleModel < CouchRest::Model::Base
  use_database "benchmark"

  property :name, String
  property :date, Date

  timestamps!

  design do
    view :by_name
  end
end


Benchmark.bm do |x|
  x.report("Create:       ") do
    100.times do |i|
      m = SampleModel.new(
        name: Faker::Name.name, 
        date: Faker::Date.between(1.year.ago, Date.today)
      )
      m.save!
    end
  end

  # Make sure the view is fresh
  SampleModel.by_name.limit(1).rows

  x.report("Fetch:        ") do
    SampleModel.by_name.rows.each do |row|
      row.doc.to_json # Causes each doc to be fetched
    end
  end

  if CouchRest::Model::VERSION >= '2.1.0'
    x.report("Fetch w/block:") do
      SampleModel.by_name.rows do |row|
        row.doc.to_json # Causes each doc to be fetched
      end
    end
  end
end

SampleModel.database.delete!

