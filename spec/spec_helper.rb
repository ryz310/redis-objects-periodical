# frozen_string_literal: true

require 'simplecov'
require 'simplecov_json_formatter'

SimpleCov.command_name(ENV.fetch('SIMPLECOV_COMMAND_NAME', 'rspec'))
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
]
SimpleCov.start

require 'pry'
require 'timecop'
require 'redis-objects-periodical'

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
    Timecop.return
  end
end
