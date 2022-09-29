# frozen_string_literal: true

class Redis
  module RecurringAtIntervals
    def initialize(key, *args)
      @original_key = key
      super(redis_periodical_field_key(current_time), *args)
    end

    attr_reader :original_key

    def [](date_or_time, length = nil)
      if date_or_time.is_a? Range
        range(date_or_time.first, date_or_time.max)
      elsif length
        case length <=> 0
        when 1  then range(date_or_time, next_key(date_or_time, length - 1))
        when 0  then empty_value
        when -1 then nil  # Ruby does this (a bit weird)
        end
      else
        get_value_from_redis(redis_periodical_field_key(date_or_time))
      end
    end
    alias slice []

    def delete_at(date_or_time)
      delete_from_redis(redis_periodical_field_key(date_or_time))
    end

    def range(start_date_or_time, end_date_or_time)
      keys = []
      date_or_time = normalize(start_date_or_time)

      loop do
        break if date_or_time > normalize(end_date_or_time)

        keys << redis_periodical_field_key(date_or_time)
        date_or_time = next_key(date_or_time)
      end

      get_values_from_redis(keys)
    end

    def at(date_or_time)
      get_redis_object(redis_periodical_field_key(date_or_time))
    end

    def current_time
      @current_time ||= Time.respond_to?(:current) ? Time.current : Time.now
    end

    private

    def get_redis_object(_key)
      raise 'not implemented'
    end

    def get_value_from_redis(_key)
      raise 'not implemented'
    end

    def get_values_from_redis(_keys)
      raise 'not implemented'
    end

    def delete_from_redis(_key)
      raise 'not implemented'
    end

    def redis_periodical_field_key(_date_or_time)
      raise 'not implemented'
    end

    def next_key(_date_or_time, _length = 1)
      raise 'not implemented'
    end

    def normalize(date_or_time)
      next_key(date_or_time, 0)
    end
  end
end
