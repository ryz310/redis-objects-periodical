# frozen_string_literal: true
require File.dirname(__FILE__) + '/base_counter_object'

class Redis
  class MinutelyCounter < BaseCounterObject
    def range(start_time, end_time)
      keys =
        (start_time.to_i..end_time.to_i)
        .step(60)
        .map { |integer| redis_daily_field_key(Time.at(integer)) }
      redis.mget(*keys).map(&:to_i)
    end

    private

    def redis_daily_field_key(time)
      time_key = time.strftime('%Y-%m-%dT%H:%M')
      [original_key, time_key].flatten.join(':')
    end

    def next_key(time, length)
      time + 60 * (length - 1)
    end
  end
end
