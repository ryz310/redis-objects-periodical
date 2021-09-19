# frozen_string_literal: true

class Redis
  class MonthlyCounter < Counter
    def initialize(key, *args)
      @original_key = key
      @current_date = (Time.respond_to?(:current) ? Time.current : Time.now).to_date
      super(redis_daily_field_key(current_date), *args)
    end

    attr_reader :original_key, :current_date

    def [](date, length = nil)
      if date.is_a? Range
        range(date.first, date.max)
      elsif length
        case length <=> 0
        when 1  then range(date, date.next_month(length - 1))
        when 0  then []
        when -1 then nil  # Ruby does this (a bit weird)
        end
      else
        at(date)
      end
    end
    alias slice []

    def delete(date)
      redis.del(redis_daily_field_key(date))
    end

    def range(start_date, end_date)
      keys = (start_date..end_date).map { |date| redis_daily_field_key(date) }.uniq
      redis.mget(*keys).map(&:to_i)
    end

    def at(date)
      redis.get(redis_daily_field_key(date)).to_i
    end

    private

    def redis_daily_field_key(date)
      date_key = date.strftime('%Y-%m')
      [original_key, date_key].flatten.join(':')
    end
  end
end
