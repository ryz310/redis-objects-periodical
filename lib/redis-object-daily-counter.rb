# frozen_string_literal: true

require 'redis-objects'
require_relative 'redis/daily_counter'
require_relative 'redis/objects/daily_counters'
require_relative 'redis/objects/daily-counter/version'

class Redis
  module Objects
    class << self
      alias original_included included

      def included(klass)
        original_included(klass)

        # Pull in each object type
        klass.send :include, Redis::Objects::DailyCounters
      end
    end
  end
end
