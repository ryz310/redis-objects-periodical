# frozen_string_literal: true

require_relative 'lib/redis/objects/daily-counter/version'

Gem::Specification.new do |spec|
  spec.name          = 'redis-objects-daily-counter'
  spec.version       = Redis::Objects::Daily::Counter::VERSION
  spec.authors       = ['ryz310']
  spec.email         = ['ryz310@gmail.com']

  spec.summary       = 'Daily counter within Redis::Objects'
  spec.description   = 'Daily counter within Redis::Objects. Works with any class or ORM.'
  spec.homepage      = 'https://github.com/ryz310/redis-objects-daily-counter'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ryz310/redis-objects-daily-counter'
  spec.metadata['changelog_uri'] = 'https://github.com/ryz310/redis-objects-daily-counter/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_dependency 'redis-objects'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
