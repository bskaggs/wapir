# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wapir/version'

Gem::Specification.new do |spec|
  spec.name          = "wapir"
  spec.version       = Wapir::VERSION
  spec.authors       = ["Bradley Skaggs"]
  spec.email         = ["bskaggs@acm.org"]
  spec.summary       = %q{Wikipedia API for Ruby}
  spec.description   = %q{Wikipedia API for Ruby}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_dependency "json"
  spec.add_dependency "faraday"

end
