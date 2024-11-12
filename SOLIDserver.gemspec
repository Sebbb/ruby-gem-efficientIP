# frozen_string_literal: true

require 'English'
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'SOLIDserver'
  spec.version       = '0.0.11'
  spec.date          = '2024-11-12'
  spec.authors       = ['Sebastian Roesner']
  spec.email         = ['github-rubyefficientip@roesner-online.de']
  spec.description   = "A Ruby Object wrapper of SOLIDserver's REST API"
  spec.summary       = "This gem provide a Ruby object interface to EfficientIP's SOLIDserver REST API"
  spec.homepage      = 'https://github.com/Sebbb/ruby-gem-efficientIP'
  spec.license       = 'BSD 2'

  spec.files         = `git ls-files`.split
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'json', '~> 2.3'
  spec.add_runtime_dependency 'rest-client', '~> 2.0'
end
