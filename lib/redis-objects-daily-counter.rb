# frozen_string_literal: true

require 'redis-objects'

class Redis
  autoload :DailyCounter, 'redis/daily_counter'
  autoload :WeeklyCounter, 'redis/weekly_counter'
  autoload :MonthlyCounter, 'redis/monthly_counter'
  autoload :AnnualCounter, 'redis/annual_counter'
  autoload :HourlyCounter, 'redis/hourly_counter'
  autoload :MinutelyCounter, 'redis/minutely_counter'
  autoload :DailySet, 'redis/daily_set'

  module Objects
    autoload :DailyCounters, 'redis/objects/daily_counters'
    autoload :WeeklyCounters, 'redis/objects/weekly_counters'
    autoload :MonthlyCounters, 'redis/objects/monthly_counters'
    autoload :AnnualCounters, 'redis/objects/annual_counters'
    autoload :HourlyCounters, 'redis/objects/hourly_counters'
    autoload :MinutelyCounters, 'redis/objects/minutely_counters'
    autoload :DailySets, 'redis/objects/daily_sets'

    class << self
      alias original_included included

      def included(klass)
        original_included(klass)

        # Pull in each object type
        klass.send :include, Redis::Objects::DailyCounters
        klass.send :include, Redis::Objects::WeeklyCounters
        klass.send :include, Redis::Objects::MonthlyCounters
        klass.send :include, Redis::Objects::AnnualCounters
        klass.send :include, Redis::Objects::HourlyCounters
        klass.send :include, Redis::Objects::MinutelyCounters
        klass.send :include, Redis::Objects::DailySets
      end
    end
  end
end
