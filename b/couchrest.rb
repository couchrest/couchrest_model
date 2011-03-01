#!/usr/bin/env ruby

require 'benchmark'

$:.unshift(File.dirname(__FILE__) + '/../lib')
require 'couchrest_model'

class BenchmarkCasted < Hash
  include CouchRest::Model::CastedModel
  
  property :name
end

class BenchmarkModel < CouchRest::Model::Base
  property :string, String
  property :number, Integer
  property :casted, BenchmarkCasted
  property :casted_list, [BenchmarkCasted]
end

begin
  n = 50000
  b = BenchmarkModel.new

  Benchmark.bm(25) do |x|

    # assigning

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

    # reading

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

  end
end
