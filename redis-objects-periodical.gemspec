# frozen_string_literal: true

require_relative 'lib/redis/objects/periodical/version'

Gem::Specification.new do |spec|
  spec.name          = 'redis-objects-periodical'
  spec.version       = Redis::Objects::Periodical::VERSION
  spec.authors       = ['ryz310']
  spec.email         = ['ryz310@gmail.com']

  spec.summary       = 'Extends Redis::Objects as periodical.'
  spec.description   = 'Extends Redis::Objects to switch automatically the save destination ' \
                       'within Redis on changing dates.'
  spec.homepage      = 'https://github.com/ryz310/redis-objects-periodical'
  spec.license       = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/ryz310/redis-objects-periodical'
  spec.metadata['changelog_uri'] = 'https://github.com/ryz310/redis-objects-periodical/blob/master/CHANGELOG.md'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_dependency 'redis-objects', '~> 1.0'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.metadata['rubygems_mfa_required'] = 'true'
end
