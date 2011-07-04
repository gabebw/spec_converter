# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name = %q{spec_converter}
  s.version = "0.5.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Relevance"]
  s.date = %q{2009-10-09}
  s.default_executable = %q{spec_converter}
  s.email = %q{rsanheim@gmail.com}
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files         = `git ls-files`.split("\n")
  s.homepage = %q{http://github.com/relevance/spec_converter}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Convert your tests to test/spec specs.  See http://github.com/relevance/spec_converter/ for details.}
  s.test_files    = `git ls-files -- {examples,test,spec,features}/*`.split("\n")

  s.add_development_dependency(%q<mocha>, [">= 0.9.0"])
  s.add_development_dependency(%q<rspec>, ["~> 2.6.0"])
  s.add_development_dependency('sdoc')
  s.add_development_dependency('sdoc-helpers')
  s.add_development_dependency('rdiscount')
end
