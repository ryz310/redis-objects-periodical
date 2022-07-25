# frozen_string_literal: true

require 'redis-objects'

class Redis
  autoload :DailyCounter, 'redis/daily_counter'
  autoload :WeeklyCounter, 'redis/weekly_counter'
  autoload :MonthlyCounter, 'redis/monthly_counter'
  autoload :AnnualCounter, 'redis/annual_counter'
  autoload :HourlyCounter, 'redis/hourly_counter'
  autoload :MinutelyCounter, 'redis/minutely_counter'

  autoload :DailyHashKey, 'redis/daily_hash_key'
  autoload :WeeklyHashKey, 'redis/weekly_hash_key'
  autoload :MonthlyHashKey, 'redis/monthly_hash_key'
  autoload :AnnualHashKey, 'redis/annual_hash_key'
  autoload :HourlyHashKey, 'redis/hourly_hash_key'
  autoload :MinutelyHashKey, 'redis/minutely_hash_key'

  autoload :DailySet, 'redis/daily_set'
  autoload :WeeklySet, 'redis/weekly_set'
  autoload :MonthlySet, 'redis/monthly_set'
  autoload :AnnualSet, 'redis/annual_set'
  autoload :HourlySet, 'redis/hourly_set'
  autoload :MinutelySet, 'redis/minutely_set'

  module Objects
    autoload :DailyCounters, 'redis/objects/daily_counters'
    autoload :WeeklyCounters, 'redis/objects/weekly_counters'
    autoload :MonthlyCounters, 'redis/objects/monthly_counters'
    autoload :AnnualCounters, 'redis/objects/annual_counters'
    autoload :HourlyCounters, 'redis/objects/hourly_counters'
    autoload :MinutelyCounters, 'redis/objects/minutely_counters'

    autoload :DailyHashes, 'redis/objects/daily_hashes'
    autoload :WeeklyHashes, 'redis/objects/weekly_hashes'
    autoload :MonthlyHashes, 'redis/objects/monthly_hashes'
    autoload :AnnualHashes, 'redis/objects/annual_hashes'
    autoload :HourlyHashes, 'redis/objects/hourly_hashes'
    autoload :MinutelyHashes, 'redis/objects/minutely_hashes'

    autoload :DailySets, 'redis/objects/daily_sets'
    autoload :WeeklySets, 'redis/objects/weekly_sets'
    autoload :MonthlySets, 'redis/objects/monthly_sets'
    autoload :AnnualSets, 'redis/objects/annual_sets'
    autoload :HourlySets, 'redis/objects/hourly_sets'
    autoload :MinutelySets, 'redis/objects/minutely_sets'

    class << self
      alias original_included included

      def included(klass) # rubocop:disable Metrics/MethodLength
        original_included(klass)

        # Pull in each object type
        klass.send :include, Redis::Objects::DailyCounters
        klass.send :include, Redis::Objects::WeeklyCounters
        klass.send :include, Redis::Objects::MonthlyCounters
        klass.send :include, Redis::Objects::AnnualCounters
        klass.send :include, Redis::Objects::HourlyCounters
        klass.send :include, Redis::Objects::MinutelyCounters

        klass.send :include, Redis::Objects::DailyHashes
        klass.send :include, Redis::Objects::WeeklyHashes
        klass.send :include, Redis::Objects::MonthlyHashes
        klass.send :include, Redis::Objects::AnnualHashes
        klass.send :include, Redis::Objects::HourlyHashes
        klass.send :include, Redis::Objects::MinutelyHashes

        klass.send :include, Redis::Objects::DailySets
        klass.send :include, Redis::Objects::WeeklySets
        klass.send :include, Redis::Objects::MonthlySets
        klass.send :include, Redis::Objects::AnnualSets
        klass.send :include, Redis::Objects::HourlySets
        klass.send :include, Redis::Objects::MinutelySets
      end
    end
  end
end
