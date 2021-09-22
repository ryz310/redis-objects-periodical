# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"

class Redis
  class BaseCounterObject < Counter
    include RecurringAtIntervals

    private

    def get_value_from_redis(key)
      redis.get(key).to_i
    end

    def get_values_from_redis(keys)
      redis.mget(*keys).map(&:to_i)
    end

    def delete_from_redis(key)
      redis.del(key)
    end

    def redis_daily_field_key(_date_or_time)
      raise 'not implemented'
    end

    def next_key(_date, _length)
      raise 'not implemented'
    end
  end
end
