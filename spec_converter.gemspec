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
  s.executables = ["spec_converter"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
    ".gitignore",
     "CHANGELOG",
     "Manifest",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "bin/spec_converter",
     "examples/spec_converter_example.rb",
     "lib/spec_converter.rb",
     "spec_converter.gemspec"
  ]
  s.homepage = %q{http://github.com/relevance/spec_converter}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Convert your tests to test/spec specs.  See http://github.com/relevance/spec_converter/ for details.}
  s.test_files = [
    "examples/spec_converter_example.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<mocha>, [">= 0.9.0"])
      s.add_development_dependency(%q<micronaut>, [">= 0.3.0"])
      s.add_development_dependency('sdoc')
      s.add_development_dependency('sdoc-helpers')
      s.add_development_dependency('rdiscount')
    else
      s.add_dependency(%q<mocha>, [">= 0.9.0"])
      s.add_dependency(%q<micronaut>, [">= 0.3.0"])
      s.add_dependency('sdoc')
      s.add_dependency('sdoc-helpers')
      s.add_dependency('rdiscount')
    end
  else
    s.add_dependency(%q<mocha>, [">= 0.9.0"])
    s.add_dependency(%q<micronaut>, [">= 0.3.0"])
    s.add_dependency('sdoc')
    s.add_dependency('sdoc-helpers')
    s.add_dependency('rdiscount')
  end
end
