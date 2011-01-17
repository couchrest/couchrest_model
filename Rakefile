require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require "rake/rdoctask"
 
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

desc "Run all specs"
Rspec::Core::RakeTask.new(:spec) do |spec|
	spec.rspec_opts = ["--color"]
	spec.pattern = 'spec/**/*_spec.rb'
end

desc "Print specdocs"
Rspec::Core::RakeTask.new(:doc) do |spec|
	spec.rspec_opts = ["--format", "specdoc"]
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
