# frozen_string_literal: true

require 'bundler/gem_helper'

Bundler::GemHelper.install_tasks(name: 'redis-objects-periodical')

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

task default: %i[spec rubocop]
