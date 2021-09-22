# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/base_counter_object"

class Redis
  class WeeklyCounter < BaseCounterObject
    private

    def redis_daily_field_key(date_or_time)
      date_key = date_or_time.strftime('%YW%W')
      [original_key, date_key].flatten.join(':')
    end

    def next_key(date, length = 1)
      date + 7 * length
    end
  end
end
