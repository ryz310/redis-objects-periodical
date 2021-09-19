# frozen_string_literal: true
require File.dirname(__FILE__) + '/base_counter_object'

class Redis
  class MonthlyCounter < BaseCounterObject
    private

    def redis_daily_field_key(date)
      date_key = date.strftime('%Y-%m')
      [original_key, date_key].flatten.join(':')
    end

    def next_key(date, length)
      date.next_month(length - 1)
    end
  end
end
