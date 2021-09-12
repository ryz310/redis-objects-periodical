# frozen_string_literal: true

require 'redis-objects'
require_relative 'redis_object_counter/redis/daily_counter'
require_relative 'redis_object_counter/redis/objects/daily_counters'
require_relative 'redis_object_counter/version'

module RedisObjectCounter
  class Error < StandardError; end
  # Your code goes here...
end
