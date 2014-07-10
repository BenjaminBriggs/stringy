# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stringy/version'

Gem::Specification.new do |spec|
  spec.name          = "stringy"
  spec.version       = Stringy::VERSION
  spec.authors       = ["Benjamin Briggs"]
  spec.email         = ["ben@palringo.com"]
  spec.summary       = "A tool for extracting the strings from a xcode project."
  spec.description   = "This is an in house project to make extracting the .stings files from an xcode project including the storyboards"
  spec.homepage      = "https://github.com/BenjaminBriggs/stringy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", '~> 1.6'
  spec.add_development_dependency "rake", '~> 10.3'
  
  spec.add_dependency "thor", '~> 0.19'
end
