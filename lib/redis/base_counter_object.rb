# frozen_string_literal: true

class Redis
  class BaseCounterObject < Counter
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

    def delete(date_or_time)
      redis.del(redis_daily_field_key(date_or_time))
    end

    def range(start_date, end_date)
      keys = (start_date..end_date).map { |date| redis_daily_field_key(date) }.uniq
      redis.mget(*keys).map(&:to_i)
    end

    def at(date_or_time)
      redis.get(redis_daily_field_key(date_or_time)).to_i
    end

    def current_time
      @current_time ||= Time.respond_to?(:current) ? Time.current : Time.now
    end

    private

    def redis_daily_field_key(_date_or_time)
      raise 'not implemented'
    end

    def next_key(_date, _length)
      raise 'not implemented'
    end
  end
end
