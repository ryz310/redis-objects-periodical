# frozen_string_literal: true

class Redis
  class DailySet < Set
    def initialize(key, *args)
      @original_key = key
      super(redis_daily_field_key(current_time), *args)
    end

    attr_reader :original_key

    def [](date_or_time, length = nil)
      if date_or_time.is_a? Range
        range(date_or_time.first, date_or_time.max)
      elsif length
        case length <=> 0
        when 1  then range(date_or_time, next_key(date_or_time, length))
        when 0  then []
        when -1 then nil  # Ruby does this (a bit weird)
        end
      else
        at(date_or_time)
      end
    end
    alias slice []

    def delete_at(date_or_time)
      redis.del(redis_daily_field_key(date_or_time))
    end

    def range(start_date, end_date)
      keys = (start_date..end_date).map { |date| redis_daily_field_key(date) }.uniq
      redis.sunion(*keys).map { |v| unmarshal(v) }
    end

    def at(date_or_time)
      vals = redis.smembers(redis_daily_field_key(date_or_time))
      vals.nil? ? [] : vals.map { |v| unmarshal(v) }
    end

    def current_time
      @current_time ||= Time.respond_to?(:current) ? Time.current : Time.now
    end

    private

    def redis_daily_field_key(date_or_time)
      date_key = date_or_time.strftime('%Y-%m-%d')
      [original_key, date_key].flatten.join(':')
    end

    def next_key(date, length)
      date + length - 1
    end
  end
end
