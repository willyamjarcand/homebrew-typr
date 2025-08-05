# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "typr"
  spec.version       = "0.1.0"
  spec.authors       = ["Willyam Arcand"]
  spec.email         = ["willyam.arcand@example.com"]

  spec.summary       = "A terminal-based typing speed test"
  spec.description   = "Terminal typing speed test with real-time feedback, WPM calculation, and accuracy tracking"
  spec.homepage      = "https://github.com/willyamarcand/typr"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = ["typr.rb", "bin/typr"]
  spec.bindir = "bin"
  spec.executables = ["typr"]
  spec.require_paths = ["."]

  spec.add_development_dependency "bundler", "~> 2.0"
end