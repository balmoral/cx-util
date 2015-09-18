# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cx/util/version'

Gem::Specification.new do |s|
  s.name          = 'cx-util'
  s.version       = CX::Util::VERSION
  s.date          = '2015-04-26'
  s.summary       = 'CX utility classes'
  s.authors       = ['Colin Gunn']
  s.email         = 'colgunn@icloud.com'
  s.homepage      = 'http://rubygems.org/gems/cx-util' # TODO: push to rubygems ??
  s.license       = 'MIT'

  s.files         = `git ls-files -z`.split("\x0")
  s.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency(%q<tzinfo>)
  s.add_dependency(%q<cx-core>)
end
