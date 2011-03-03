#!/usr/bin/env ruby

require 'benchmark'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'couchrest_model'

class BenchmarkCasted < Hash
  include CouchRest::Model::CastedModel
  
  property :name
end

class BenchmarkModel < CouchRest::Model::Base
  use_database CouchRest.database!(ENV['BENCHMARK_DB'] || "http://localhost:5984/test")

  property :string, String
  property :number, Integer
  property :casted, BenchmarkCasted
  property :casted_list, [BenchmarkCasted]
end

# set dirty configuration, return previous configuration setting
def set_dirty(value)
  orig = nil
  CouchRest::Model::Base.configure do |config|
    orig = config.use_dirty
    config.use_dirty = value
  end
  BenchmarkModel.instance_eval do
    self.use_dirty = value
  end
  orig
end

def run_benchmark
  n = 50000     # property operation count
  db_n = 1000   # database operation count
  b = BenchmarkModel.new

  Benchmark.bm(30) do |x|

    # property assigning

    x.report("assign string:") do
      n.times { b.string = "test" }
    end

    x.report("assign integer:") do
      n.times { b.number = 1 }
    end

    x.report("assign casted hash:") do
      n.times { b.casted = { 'name' => 'test' } }
    end

    x.report("assign casted hash list:") do
      n.times { b.casted_list = [{ 'name' => 'test' }] }
    end

    # property reading

    x.report("read string") do
      n.times { b.string }
    end

    x.report("read integer") do
      n.times { b.number }
    end

    x.report("read casted hash") do
      n.times { b.casted }
    end

    x.report("read casted hash list") do
      n.times { b.casted_list }
    end

    if ENV['BENCHMARK_DB']
      # db writing
      x.report("write changed record to db") do
        db_n.times { |i| b.string = "test#{i}"; b.save }  
      end

      x.report("write unchanged record to db") do
        db_n.times { b.save }  
      end

      # db reading
      x.report("read record from db") do
        db_n.times { BenchmarkModel.find(b.id) }
      end

    end

  end
end

begin
  puts "with use_dirty true"
  set_dirty(true)
  run_benchmark
    
  puts "\nwith use_dirty false"
  set_dirty(false)
  run_benchmark
end
