# frozen_string_literal: true

require 'simplecov'
SimpleCov.start

require 'pry'
require 'redis_object_counter'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.before :suite do
    Redis::Objects.redis = Redis.new(host: 'redis', port: 6379)
  end

  config.after do
    Redis.new(host: 'redis', port: 6379).flushdb
  end
end
