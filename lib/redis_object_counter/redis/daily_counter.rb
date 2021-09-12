# frozen_string_literal: true

class Redis
  class DailyCounter < Counter
    def initialize(key, *args)
      @original_key = key
      @date = Date.today
      super(redis_daily_field_key(date), *args)
    end

    attr_reader :original_key, :date

    def sum(duration)
      ((date - duration)..date).sum do |day|
        redis.get(redis_daily_field_key(day)).to_i
      end
    end

    def average(duration)
      sum(duration) / duration.to_f
    end

    private

    def redis_daily_field_key(date)
      [original_key, date].flatten.join(':')
    end
  end
end
