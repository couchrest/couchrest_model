require 'rake'
require "rake/rdoctask"

$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require 'couchrest_model'

begin
  require 'rspec'
  require 'rspec/core/rake_task'
rescue LoadError
  puts <<-EOS
To use rspec for testing you must install rspec gem:
    gem install rspec
EOS
  exit(0)
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "couchrest_model"
    gemspec.summary = "Extends the CouchRest Document for advanced modelling."
    gemspec.description = "CouchRest Model provides aditional features to the standard CouchRest Document class such as properties, view designs, associations, callbacks, typecasting and validations."
    gemspec.email = "jchris@apache.org"
    gemspec.homepage = "http://github.com/couchrest/couchrest_model"
    gemspec.authors = ["J. Chris Anderson", "Matt Aimonetti", "Marcos Tapajos", "Will Leinweber", "Sam Lown"]
    gemspec.extra_rdoc_files = %w( README.md LICENSE THANKS.md )
    gemspec.files = %w( LICENSE README.md Rakefile THANKS.md history.txt couchrest.gemspec) + Dir["{examples,lib,spec}/**/*"] - Dir["spec/tmp"]
    gemspec.has_rdoc = true
    gemspec.add_dependency("couchrest", "~> 1.0.0")
    gemspec.add_dependency("mime-types", "~> 1.15")
    gemspec.add_dependency("activesupport", "~> 3.0.0.rc")
    gemspec.add_dependency("activemodel", "~> 3.0.0.rc")
    gemspec.add_dependency("tzinfo", "~> 0.3.22")
    gemspec.add_development_dependency('rspec', '~> 2.0.0.beta.19')
    gemspec.version = CouchRest::Model::VERSION
    gemspec.date = Time.now.strftime("%Y-%m-%d")
    gemspec.require_path = "lib"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc "Run all specs"
Rspec::Core::RakeTask.new(:spec) do |spec|
	spec.spec_opts = ["--color"]
	spec.pattern = 'spec/**/*_spec.rb'
end

desc "Print specdocs"
Rspec::Core::RakeTask.new(:doc) do |spec|
	spec.spec_opts = ["--format", "specdoc"]
	spec.pattern = 'spec/*_spec.rb'
end

desc "Generate the rdoc"
Rake::RDocTask.new do |rdoc|
  files = ["README.rdoc", "LICENSE", "lib/**/*.rb"]
  rdoc.rdoc_files.add(files)
  rdoc.main = "README.rdoc"
  rdoc.title = "CouchRest: Ruby CouchDB, close to the metal"
end

desc "Run the rspec"
task :default => :spec

module Rake
  def self.remove_task(task_name)
    Rake.application.instance_variable_get('@tasks').delete(task_name.to_s)
  end
end

Rake.remove_task("github:release")
Rake.remove_task("release")
