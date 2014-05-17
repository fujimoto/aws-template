# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'aws/template/version'

Gem::Specification.new do |spec|
  spec.name          = "aws-template"
  spec.version       = AWS::VERSION
  spec.authors       = ["Masaki Fujimoto"]
  spec.email         = ["masaki.fujimoto@gree.net"]
  spec.summary       = "AWS Template"
  spec.description   = "aws-template provides automatic AWS configuration for typical web services"
  spec.homepage      = "https://github.com/fujimoto/aws-template"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency 'aws-sdk'
end
