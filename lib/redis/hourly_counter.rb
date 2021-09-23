# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/recurring_at_intervals"
require "#{File.dirname(__FILE__)}/base_counter_object"
require "#{File.dirname(__FILE__)}/recurring_at_intervals/hourly"

class Redis
  class HourlyCounter < Counter
    include RecurringAtIntervals
    include BaseCounterObject
    include Hourly
  end
end
