# frozen_string_literal: true

require_relative 'lib/redis/objects/daily-counter/version'

Gem::Specification.new do |spec|
  spec.name          = 'redis-object-daily-counter'
  spec.version       = Redis::Objects::Daily::Counter::VERSION
  spec.authors       = ['ryz310']
  spec.email         = ['ryz310@gmail.com']

  spec.summary       = 'WIP'
  spec.description   = 'WIP'
  spec.homepage      = 'https://github.com/ryz310'
  spec.license       = 'MIT'

  spec.metadata['allowed_push_host'] = 'WIP'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ryz310'
  spec.metadata['changelog_uri'] = 'https://github.com/ryz310'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6.0'

  spec.add_dependency 'redis-objects'

  spec.add_development_dependency 'bundler', '>= 2.0'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec_junit_formatter'
  spec.add_development_dependency 'rubocop', '~> 0.80'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'simplecov', '0.21.2'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'yard'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
