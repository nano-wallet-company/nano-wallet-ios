# -*- encoding: utf-8 -*-
# stub: CFPropertyList 3.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "CFPropertyList"
  s.version = "3.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Christian Kruse"]
  s.date = "2018-01-13"
  s.description = "This is a module to read, write and manipulate both binary and XML property lists as defined by apple."
  s.email = "cjk@defunct.ch"
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc"]
  s.homepage = "http://github.com/ckruse/CFPropertyList"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.8"
  s.summary = "Read, write and manipulate both binary and XML property lists as defined by apple"

  s.installed_by_version = "2.4.8" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0.7.0"])
    else
      s.add_dependency(%q<rake>, [">= 0.7.0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0.7.0"])
  end
end
