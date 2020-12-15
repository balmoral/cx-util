# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cx/util/version'

Gem::Specification.new do |spec|
  spec.name          = 'cx-util'
  spec.version       = CX::Util::VERSION
  spec.date          = '2015-04-26'
  spec.summary       = 'CX utility classes'
  spec.authors       = ['Colin Gunn']
  spec.email         = 'colgunn@icloud.com'
  spec.homepage      = 'http://rubygemspec.org/gems/cx-util' # TODO: push to rubygems ??
  spec.license       = 'MIT'

  spec.files         = Dir[File.join("lib", "**", "*"), File.join("robe", "**", "*")]
  # spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency('scanf')
  spec.add_dependency('tzinfo')
  spec.add_dependency 'cx-core', '~> 1.0'
end
