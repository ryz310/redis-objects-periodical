# frozen_string_literal: true

class Redis
  module RecurringAtIntervals
    module Weekly
      private

      def redis_periodical_field_key(date_or_time)
        date_key = date_or_time.strftime('%YW%W')
        [original_key, date_key].flatten.join(':')
      end

      def next_key(date, length = 1)
        date + 7 * length
      end
    end
  end
end
