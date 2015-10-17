# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'secure_attachment/version'

Gem::Specification.new do |spec|
  spec.name          = 'secure_attachment'
  spec.version       = SecureAttachment::VERSION
  spec.authors       = ['sowmya']
  spec.email         = ['sowmya.gopinath@RACKSPACE.COM']
  spec.summary       = 'Secures documents for storage in cloud.'
  spec.description   = 'Encrypt uploaded documents for storage in cloud.'
  spec.homepage      = 'https://github.rackspace.com/GSCS/secure_attachment'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'rails', '>= 3.2'
  spec.add_dependency 'fernet', '~> 2.1'

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'paperclip', '~> 4.2', '>= 4.2.0'
  spec.add_development_dependency 'rspec', '~> 3.1', '>= 3.1.0'
  spec.add_development_dependency 'pry', '~> 0.10', '>= 0.10.1'
  spec.add_development_dependency 'database_cleaner', '~> 1.3', '>= 1.3.0'
  spec.add_development_dependency 'sqlite3', '~> 1.3', '>= 1.3.9'
  spec.add_development_dependency 'guard', '~> 2.6', '>= 2.6.1'
  spec.add_development_dependency 'guard-rspec', '~> 4.2', '>= 4.2.10'
  spec.add_development_dependency 'guard-bundler', '~> 2.0', '>= 2.0.0'

end
