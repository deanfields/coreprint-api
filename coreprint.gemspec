# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'coreprint/version'

Gem::Specification.new do |spec|
  spec.name          = "coreprint"
  spec.version       = Coreprint::VERSION
  spec.authors       = ["Dean Fields"]
  spec.email         = ["dean@deanfields.co.uk"]
  spec.summary       = "Gem wrapper for Coreprint Web Services"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"

  spec.add_dependency "httparty", "0.13.3"
  spec.add_dependency "json", "1.8.2"

end
