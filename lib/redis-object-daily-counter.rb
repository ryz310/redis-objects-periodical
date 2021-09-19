# frozen_string_literal: true

require 'redis-objects'

class Redis
  autoload :DailyCounter, 'redis/daily_counter'
  autoload :WeeklyCounter, 'redis/weekly_counter'

  module Objects
    autoload :DailyCounters, 'redis/objects/daily_counters'
    autoload :WeeklyCounters, 'redis/objects/weekly_counters'

    class << self
      alias original_included included

      def included(klass)
        original_included(klass)

        # Pull in each object type
        klass.send :include, Redis::Objects::DailyCounters
        klass.send :include, Redis::Objects::WeeklyCounters
      end
    end
  end
end
