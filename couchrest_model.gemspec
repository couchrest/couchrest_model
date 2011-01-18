# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{couchrest_model}
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new("> 1.3.1") if s.respond_to? :required_rubygems_version=
  s.authors = ["J. Chris Anderson", "Matt Aimonetti", "Marcos Tapajos", "Will Leinweber", "Sam Lown"]
  s.date = %q{2011-01-16}
  s.description = %q{CouchRest Model provides aditional features to the standard CouchRest Document class such as properties, view designs, associations, callbacks, typecasting and validations.}
  s.email = %q{jchris@apache.org}
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md",
    "THANKS.md"
  ]
  s.homepage = %q{http://github.com/couchrest/couchrest_model}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Extends the CouchRest Document for advanced modelling.}
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency(%q<couchrest>, "~> 1.0.1")
  s.add_dependency(%q<mime-types>, "~> 1.15")
  s.add_dependency(%q<activemodel>, "~> 3.0.0")
  s.add_dependency(%q<tzinfo>, "~> 0.3.22")
  s.add_dependency(%q<railties>, "~> 3.0.0")
  s.add_development_dependency(%q<rspec>, ">= 2.0.0")
  s.add_development_dependency(%q<rack-test>, ">= 0.5.7")
end

