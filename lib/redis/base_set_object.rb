# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"

class Redis
  class BaseSetObject < Set
    include RecurringAtIntervals

    private

    def get_value_from_redis(key)
      vals = redis.smembers(key)
      vals.nil? ? [] : vals.map { |v| unmarshal(v) }
    end

    def get_values_from_redis(keys)
      redis.sunion(*keys).map { |v| unmarshal(v) }
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
