# frozen_string_literal: true

class Redis
  module RecurringAtIntervals
    module Hourly
      private

      def redis_periodical_field_key(time)
        time_key = time.strftime('%Y-%m-%dT%H')
        [original_key, time_key].flatten.join(':')
      end

      def next_key(time, length = 1)
        time + 3600 * length
      end
    end
  end
end
