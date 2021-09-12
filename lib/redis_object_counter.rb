# frozen_string_literal: true

require 'redis-objects'
require_relative 'redis_object_counter/redis/daily_counter'
require_relative 'redis_object_counter/redis/objects/daily_counters'
require_relative 'redis_object_counter/version'

module RedisObjectCounter
  class Error < StandardError; end
  # Your code goes here...
end

class Redis
  module Objects
    class << self
      alias original_included included

      def included(klass)
        original_included(klass)
        klass.send :include, Redis::Objects::DailyCounters
      end
    end
  end
end
