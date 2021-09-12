# frozen_string_literal: true

class Redis
  class DailyCounter < Counter
    def initialize(key, *args)
      @original_key = key
      @current_date = Date.today
      super(redis_daily_field_key(current_date), *args)
    end

    attr_reader :original_key, :current_date

    def get_value(date)
      redis.get(redis_daily_field_key(date)).to_i
    end

    def values(date_range)
      date_range.map { |date| get_value(date) }
    end

    def delete(date)
      redis.del(redis_daily_field_key(date))
    end

    private

    def redis_daily_field_key(date)
      [original_key, date.to_date].flatten.join(':')
    end
  end
end
