# frozen_string_literal: true

class Redis
  module RecurringAtIntervals
    module Annual
      private

      def redis_periodical_field_key(date_or_time)
        date_key = date_or_time.strftime('%Y')
        [original_key, date_key].flatten.join(':')
      end

      def next_key(date_or_time, length = 1)
        date_or_time.to_date.next_year(length)
      end
    end
  end
end
