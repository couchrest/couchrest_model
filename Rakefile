require 'rake'
require "rake/rdoctask"
require File.join(File.expand_path(File.dirname(__FILE__)),'lib','couchrest','extended_document')

begin
  require 'spec/rake/spectask'
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
    gemspec.name = "samlown-couchrest_extended_document"
    gemspec.summary = "Extend CouchRest Document class with useful features."
    gemspec.description = "CouchRest::ExtendedDocument provides aditional features to the standard CouchRest::Document class such as properties, view designs, callbacks, typecasting and validations."
    gemspec.email = "jchris@apache.org"
    gemspec.homepage = "http://github.com/samlown/couchrest_extended_document"
    gemspec.authors = ["J. Chris Anderson", "Matt Aimonetti", "Marcos Tapajos", "Will Leinweber"]
    gemspec.extra_rdoc_files = %w( README.md LICENSE THANKS.md )
    gemspec.files = %w( LICENSE README.md Rakefile THANKS.md history.txt couchrest.gemspec) + Dir["{examples,lib,spec,utils}/**/*"] - Dir["spec/tmp"]
    gemspec.has_rdoc = true
    gemspec.add_dependency("samlown-couchrest", ">= 1.0.0")
    gemspec.add_dependency("mime-types", ">= 1.15")
    gemspec.add_dependency("activesupport", ">= 2.3.0")
    gemspec.version = CouchRest::ExtendedDocument::VERSION
    gemspec.date = "2008-11-22"
    gemspec.require_path = "lib"
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

desc "Run all specs"
Spec::Rake::SpecTask.new('spec') do |t|
	t.spec_opts = ["--color"]
	t.spec_files = FileList['spec/**/*_spec.rb']
end

desc "Print specdocs"
Spec::Rake::SpecTask.new(:doc) do |t|
	t.spec_opts = ["--format", "specdoc"]
	t.spec_files = FileList['spec/*_spec.rb']
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
