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

    def values(duration)
      date_range(duration).map { |date| get_value(date) }
    end

    private

    def date_range(duration)
      (current_date - duration + 1)..current_date
    end

    def redis_daily_field_key(date)
      [original_key, date.to_date].flatten.join(':')
    end
  end
end
