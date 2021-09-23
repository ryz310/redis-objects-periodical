# frozen_string_literal: true

class Redis
  module RecurringAtIntervals
    module Minutely
      private

      def redis_daily_field_key(time)
        time_key = time.strftime('%Y-%m-%dT%H:%M')
        [original_key, time_key].flatten.join(':')
      end

      def next_key(time, length = 1)
        time + 60 * length
      end
    end
  end
end
